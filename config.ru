$LOAD_PATH << File.dirname(__FILE__)
require 'api'
require 'lifx'

$lifx = LIFX::Client.lan
$lifx.discover

run API
