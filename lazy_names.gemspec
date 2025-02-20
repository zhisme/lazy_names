# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lazy_names/version'

Gem::Specification.new do |spec|
  spec.name = 'lazy_names'
  spec.version = LazyNames::VERSION
  spec.authors = ['zhisme']
  spec.email = ['evdev34@gmail.com']

  spec.description = <<~DESC
    lazy_names is ruby programmer friend. You can save your time not typing long
    error-phone constants/classes but defining short and nice versions of them.
  DESC
  spec.summary = 'Define short constants to frequently used classes/constants'
  spec.homepage = 'https://github.com/zhisme/lazy_names'
  spec.license = 'MIT'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3.3'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
