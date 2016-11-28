# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cf/uaa/version'

Gem::Specification.new do |spec|
  spec.name          = "cf-uaa"
  spec.version       = CF::UAA::VERSION
  spec.authors       = ["Tyler Phelan", "Yuki Nishijima"]
  spec.email         = ["tphelan@pivotal.io", "mail@yukinishijima.net"]
  spec.summary       = %q{Ruby client for CF UAA}
  spec.description   = %q{Provides access to CF UAA}
  spec.homepage      = "https://github.com/tylerphelan/cf-uaa"
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^(spec)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
