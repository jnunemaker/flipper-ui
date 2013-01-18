source 'https://rubygems.org'
gemspec

gem 'rake'
gem 'flipper', :git => 'git@github.com:jnunemaker/flipper.git'

gem 'shotgun'

group(:guard) do
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'terminal-notifier-guard'
  gem 'rb-fsevent'
end

group(:test) do
  gem 'rspec'
  gem 'rack-test'
end
