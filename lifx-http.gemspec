# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lifx-http/version'

Gem::Specification.new do |spec|
  spec.name          = "lifx-http"
  spec.version       = LIFXHTTP::VERSION
  spec.authors       = ["Jack Chen (chendo)"]
  spec.email         = ["github+lifx-http@chen.do"]
  spec.description   = %q{A HTTP API for LIFX.}
  spec.summary       = %q{A HTTP API for interacting with LIFX devices.}
  spec.homepage      = "https://github.com/chendo/lifx-http"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/).reject { |f| f =~ /^script\// }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.0"

  spec.add_dependency "rack", "~> 1.5"
  spec.add_dependency "rack-cors", "~> 0.2"
  spec.add_dependency "lifx", "= 0.4.5"
  spec.add_dependency "grape", "~> 0.6"
  spec.add_dependency "grape-entity", "~> 0.4"
  spec.add_dependency "grape-swagger", "~> 0.7"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.1"
end
