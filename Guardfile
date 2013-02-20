# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$}) { "spec" }
  watch(%r{^lib/(.+)\.rb$}) { "spec" }
  watch('spec/helper.rb')  { "spec" }
end

coffee_options = {
  :input => 'lib/flipper/ui/assets/javascripts',
  :output => 'lib/flipper/ui/public/js',
  :all_on_start => false,
}
guard 'coffeescript', coffee_options

sass_options = {
  :input => 'lib/flipper/ui/assets/stylesheets',
  :output => 'lib/flipper/ui/public/css',
}
guard 'sass', sass_options
