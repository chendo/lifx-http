require 'grape'
require 'grape-entity'
require 'byebug'

class API < Grape::API
  module Entities
    class Light < Grape::Entity
      format_with(:iso_timestamp) { |dt| dt.iso8601 }
      expose :id
      expose :label
      expose :site_id do |light, options|
        light.site.id
      end
      expose :on do |light, options|
        light.on?
      end
      expose :color
      expose :last_seen
      expose :age
    end
  end

  format :json
  default_format :json
  helpers do
    def lifx
      $lifx
    end
  end

  get "lights" do
    present lifx.lights.values, with: Entities::Light
  end

  resources :lights do
    params do
      requires :light_id, type: String, desc: 'Light ID'
    end

    namespace ":light_id" do
      after_validation do
        @light = lifx.lights[params[:light_id]]
        if @light.nil?
          raise "Light not found"
        end
      end

      put :on do
        @light.on!
      end

      put :off do
        @light.off!
      end

      params do
        requires :hue, type: Float
        requires :saturation, type: Float
        requires :brightness, type: Float
        optional :kelvin, type: Integer, default: 3_500
        optional :duration, type: Float, default: 0.5
      end
      put :color do
        color = LIFX::Color.hsbk(
          params[:hue],
          params[:saturation],
          params[:brightness],
          params[:kelvin]
        )
        @light.set_color(color, params[:duration])
      end

      params do
        requires :label, type: String, regexp: /^.{,32}$/
      end
      put :label do
        @light.set_label(params[:label])
      end
    end
  end
end
