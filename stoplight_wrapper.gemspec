
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "stoplight_wrapper/version"

Gem::Specification.new do |spec|
  spec.name          = "stoplight_wrapper"
  spec.version       = StoplightWrapper::VERSION
  spec.authors       = ["Mathew Bramson"]
  spec.email         = ["mathewbramson@gmail.com"]

  spec.summary       = %q{Faraday Connection wrapped with a Stoplight}
  spec.description   = %q{Utility for wrapping things in Stoplights, particular http calls.}
  spec.homepage      = 'https://github.com/mbramson/stoplight_wrapper'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday"
  spec.add_dependency "stoplight"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock"
end
