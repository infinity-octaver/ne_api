# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ne_api/version'

Gem::Specification.new do |spec|
  spec.name          = "ne_api"
  spec.version       = NeApi::VERSION
  spec.authors       = ["Yuuna Kurita","Mika Koizumi"]
  spec.email         = ["yuuna.m@gmail.com"]
  spec.summary       = %q{Next Engine API for ruby}
  spec.description   = %q{Next Engine API for ruby}
  spec.homepage      = "http://github.com/infinity-octaver/ne_api/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency 'faraday'
  spec.add_dependency 'oauth'
  spec.add_dependency 'i18n'
  spec.add_dependency 'activesupport'
  spec.add_development_dependency 'rspec'
  spec.add_dependency 'dotenv'
  spec.add_dependency 'launchy'
end
