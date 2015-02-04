# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kakurenbo_puti/version'

Gem::Specification.new do |spec|
  spec.name          = 'kakurenbo-puti'
  spec.version       = KakurenboPuti::VERSION
  spec.authors       = ['alfa-jpn']
  spec.email         = ['a.nkmr.ja@gmail.com']
  spec.homepage      = 'https://github.com/alfa-jpn/kakurenbo-puti'
  spec.license       = 'MIT'
  spec.summary       = <<-EOF
    Lightweight soft-delete gem.
  EOF
  spec.description   = <<-EOF
    kakurenbo-puti provides an ActiveRecord-friendly soft-delete gem.
    This gem does not override methods of ActiveRecord.

    I think that kakurenbo-puti is cho-iketeru! (very cool!)
  EOF

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.0'

  spec.add_dependency 'activerecord', '>= 4.1.0'

  spec.add_development_dependency 'bundler',   '~> 1.7'
  spec.add_development_dependency 'rake',      '~> 10.0'
  spec.add_development_dependency 'rspec',     '~> 3.0.0'
  spec.add_development_dependency 'yard',      '~> 0.8.7.6'
  spec.add_development_dependency 'sqlite3',   '~> 1.3.10'
  spec.add_development_dependency 'coveralls', '~> 0.7.8'
end
