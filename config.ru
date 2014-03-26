$LOAD_PATH << File.dirname(__FILE__)
require 'rack/cors'
require 'method_override'
require 'api'

use MethodOverride
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
  end
end

run API
