$LOAD_PATH << File.dirname(__FILE__)
require 'api'
require 'lifx'
require 'rack/cors'

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
  end
end

$lifx = LIFX::Client.lan
$lifx.discover

run API
