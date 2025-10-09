# frozen_string_literal: true

desc 'Run RSpec tests'
task :spec do
  sh 'bundle exec rspec'
end

desc 'Run RuboCop'
task :rubocop do
  sh 'bundle exec rubocop'
end

desc 'Run all linting and tests'
task test: [:rubocop, :spec]

desc 'Generate YARD documentation'
task :docs do
  sh 'bundle exec yard doc'
end

desc 'Clean up generated files'
task :clean do
  sh 'rm -rf coverage/ doc/ .yardoc/'
end

desc 'Build the gem'
task :build do
  sh 'gem build kapso-client-ruby.gemspec'
end

desc 'Install the gem locally'
task install: :build do
  sh 'gem install kapso-client-ruby-*.gem'
end

desc 'Release the gem'
task release: [:clean, :test, :build] do
  puts 'Run `gem push kapso-client-ruby-*.gem` to release'
end

task default: :test