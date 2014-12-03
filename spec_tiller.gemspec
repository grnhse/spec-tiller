# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spec_tiller/version'

Gem::Specification.new do |spec|
  spec.name          = "spec_tiller"
  spec.version       = SpecTiller::VERSION
  spec.authors       = ["Matt Schmaus","Josh Bazemore"]
  spec.email         = ["mschmaus201@gmail.com","jbazemore@greenhouse.io"]
  spec.description   = <<-EOF
    This gem will parse the output of calling "rspec --perform", then will redistribute
    the spec files evenly, based on file run time, across all builds established
    in the travis.yml file.
  EOF
  spec.summary       = 'Distribute spec files evenly across Travis builds, based on file run time'
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "railties"
end
