require 'grape'
require 'grape-entity'
require 'grape-swagger'
require 'byebug'

class API < Grape::API
  module Entities
    class Light < Grape::Entity
      format_with(:iso_timestamp) { |dt| dt.iso8601 }
      expose :id
      expose :label
      expose :site_id
      expose :tags
      expose :on do |light, options|
        light.on?
      end
      expose :color
      expose :last_seen
      expose :age
    end
  end

  before do
    header['Access-Control-Allow-Origin'] = '*'
    header['Access-Control-Request-Method'] = '*'
  end
  format :json
  default_format :json
  helpers do
    def lifx
      $lifx
    end

    def ensure_light_target!
      error!('Must target a single light', 400) unless @target.is_a?(LIFX::Light)
    end

    def present_target(target)
      if target.is_a?(LIFX::LightCollection)
        present target.to_a, with: Entities::Light
      else
        present target, with: Entities::Light
      end
    end
  end

  get "lights" do
    present_target(lifx.lights.lights)
  end

  resources :lights do
    params do
      requires :selector, type: String, desc: 'Light selector'
    end

    namespace ":selector" do
      after_validation do
        selector = params[:selector]
        case selector
        when /^tag:(.+)$/
          @target = lifx.lights.with_tag($1)
        when /^label:(.+)$/
          @target = lifx.lights.with_label($1)
        when /^all$/
          @target = lifx.lights
        else
          @target = lifx.lights.with_id(selector)
        end

        if @target.nil?
          error! "Could not resolve selector: selector", 404
        end
      end

      get do
        present_target(@target)
      end

      put :on do
        present_target(@target.turn_on)
      end

      put :off do
        present_target(@target.turn_off)
      end

      params do
        requires :hue, type: Float
        requires :saturation, type: Float
        requires :brightness, type: Float
        optional :kelvin, type: Integer, default: 3_500
        optional :duration, type: Float, default: 1
      end
      put :color do
        color = LIFX::Color.hsbk(
          params[:hue],
          params[:saturation],
          params[:brightness],
          params[:kelvin]
        )
        present_target(@target.set_color(color, duration: params[:duration]))
      end

      params do
        requires :label, type: String, regexp: /^.{,32}$/
      end
      put :label do
        ensure_light_target!
        present_target(@target.set_label(params[:label]))
      end

      params do
        requires :tag, type: String, regexp: /^.{1,32}$/
      end
      post :tag do
        ensure_light_target!
        present_target(@target.add_tag(params[:tag]))
      end

      params do
        requires :tag, type: String, regexp: /^.{1,32}$/
      end
      delete :tag do
        ensure_light_target!
        present_target(@target.remove_tag(params[:tag]))
      end

    end
  end

  add_swagger_documentation
end
