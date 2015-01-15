# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rotor/version'

Gem::Specification.new do |spec|
  spec.name          = "rotor"
  spec.version       = Rotor::VERSION
  spec.authors       = ["kobaltz"]
  spec.email         = ["dave@k-innovations.net"]
  spec.summary       = %q{Ruby Gem for controlling Bipolar and Unipolar motors}
  spec.description   = %q{Ruby Gem for controlling Bipolar and Unipolar Stepper Motors}
  spec.homepage      = "https://github.com/kobaltz"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "wiringpi", '~> 0'
end
