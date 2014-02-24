$LOAD_PATH << File.dirname(__FILE__)
require 'api'
require 'lifx'

$lifx = LIFX::Client.new(logger: Yell.new(STDERR, level: [:info, :warn, :error, :fatal]))
$lifx.discover

run API
