require 'grape'
require 'grape-entity'
require 'grape-swagger'
require 'lifx'

LIFX::Client.lan.discover

class API < Grape::API
  module Entities
    class Light < Grape::Entity
      format_with(:iso_timestamp) { |dt| dt.iso8601 }
      expose :id
      expose :label do |light, options|
        light.label(fetch: false)
      end
      expose :site_id
      expose :tags
      expose :on do |light, options|
        light.on?(fetch: false)
      end
      expose :color
      expose :last_seen
      expose :seconds_since_seen
    end
  end

  format :json
  default_format :json
  helpers do
    def lifx
      @lifx ||= LIFX::Client.lan
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

  desc "List of all known lights"
  get "lights" do
    present_target(lifx.lights.lights)
  end

  resources :lights do
    params do
      requires :selector, type: String, desc: "Can be 'all', 'label:[label]', 'tag:[tag]' and '[light id]'"
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

      desc "Returns light(s) based on selector"
      get do
        present_target(@target)
      end

      desc "Turn light(s) on"
      put :on do
        present_target(@target.turn_on)
      end

      desc "Turn light(s) off"
      put :off do
        present_target(@target.turn_off)
      end

      desc "Toggle light(s) power state. Will turn lights off if any are on."
      put :toggle do
        if @target.is_a?(LIFX::LightCollection)
          on = @target.to_a.any? { |light| light.on? }
          present_target(on ? @target.turn_off : @target.turn_on)
        else
          present_target(@target.on? ? @target.turn_off : @target.turn_on)
        end
      end

      desc "Set colour of light(s)"
      params do
        requires :hue, type: Float, desc: "Hue: 0-360"
        requires :saturation, type: Float, desc: "Saturation: 0-1"
        requires :brightness, type: Float, desc: "Brightness: 0-1"
        optional :kelvin, type: Integer, default: 3_500, desc: "Kelvin: 2500-10000. Defaults to 3500"
        optional :duration, type: Float, default: 1, desc: "Duration in seconds. Defaults to 1.0"
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
    end

    params do
      requires :light_id, type: String, desc: "Light ID"
    end
    namespace ":light_id" do
      after_validation do
        @target = lifx.lights.with_id(params[:light_id])
        if @target.nil?
          error!("Could not find light with ID: #{params[:light_id]}", 404)
        end
      end
      desc "Sets label on light"
      params do
        requires :label, type: String, regexp: /^.{,32}$/, desc: "Label"
      end
      put :label do
        ensure_light_target!
        present_target(@target.set_label(params[:label]))
      end

      desc "Adds a tag a light"
      params do
        requires :tag, type: String, regexp: /^.{1,32}$/, desc: "Tag"
      end
      post :tag do
        ensure_light_target!
        present_target(@target.add_tag(params[:tag]))
      end

      desc "Removes a tag from a light"
      params do
        requires :tag, type: String, regexp: /^.{1,32}$/, desc: "Tag"
      end
      delete :tag do
        ensure_light_target!
        present_target(@target.remove_tag(params[:tag]))
      end
    end
  end

  add_swagger_documentation(markdown: true)
end
