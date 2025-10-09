# frozen_string_literal: true

require_relative 'lib/kapso_client_ruby/version'

Gem::Specification.new do |spec|
  spec.name = 'kapso-client-ruby'
  spec.version = KapsoClientRuby::VERSION
  spec.authors = ['PabloB07']
  spec.email = ['pablob0798@gmail.com']

  spec.summary = 'Ruby client for the Kapso API'
  spec.description = 'A comprehensive Ruby SDK for the Kapso API with support for sending messages, managing media, templates, and more. Includes debug logging and comprehensive error handling.'
  spec.homepage = 'https://github.com/PabloB07/kapso-client-ruby'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/PabloB07/kapso-client-ruby'
  spec.metadata['changelog_uri'] = 'https://github.com/PabloB07/kapso-client-ruby/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'faraday-multipart', '~> 1.0'
  spec.add_dependency 'mime-types', '~> 3.0'
  spec.add_dependency 'dry-validation', '~> 1.10'

  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.18'
  spec.add_development_dependency 'vcr', '~> 6.0'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.20'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'yard', '~> 0.9'
end