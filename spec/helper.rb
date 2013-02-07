$:.unshift(File.expand_path('../../lib', __FILE__))

require 'rubygems'
require 'bundler'
Bundler.setup :default

require 'flipper-ui'

module JsonHelpers
  def json_response
    MultiJson.load(last_response.body)
  end
end

RSpec.configure do |config|
  config.filter_run :focused => true
  config.alias_example_to :fit, :focused => true
  config.alias_example_to :xit, :pending => true
  config.run_all_when_everything_filtered = true

  config.include JsonHelpers
end
