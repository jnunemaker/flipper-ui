$:.unshift(File.expand_path('../../lib', __FILE__))

require 'rubygems'
require 'bundler'
Bundler.setup :default

require 'flipper-ui'

require 'flipper/instrumentation/log_subscriber'
require 'logger'
require 'json'

root = Pathname(__FILE__).dirname.join('..').expand_path
log_path = root.join('log')
log_path.mkpath

logger = Logger.new(log_path.join('test.log'))
logger.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n" }
Flipper::Instrumentation::LogSubscriber.logger = logger

module JsonHelpers
  def json_response
    JSON.load(last_response.body)
  end
end

RSpec.configure do |config|
  config.filter_run :focused => true
  config.alias_example_to :fit, :focused => true
  config.alias_example_to :xit, :pending => true
  config.run_all_when_everything_filtered = true
  config.fail_fast = true

  config.include JsonHelpers
end
