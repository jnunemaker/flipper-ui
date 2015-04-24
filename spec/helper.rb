$:.unshift(File.expand_path('../../lib', __FILE__))

require 'rubygems'
require 'bundler'
Bundler.setup :default

require 'flipper-ui'
require 'flipper/instrumentation/log_subscriber'
require 'flipper/adapters/memory'
require 'rack/test'
require 'logger'
require 'json'

root = Pathname(__FILE__).dirname.join('..').expand_path
log_path = root.join('log')
log_path.mkpath

logger = Logger.new(log_path.join('test.log'))
logger.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n" }
Flipper::Instrumentation::LogSubscriber.logger = logger

module SpecHelpers
  def self.included(base)
    base.let(:flipper) { build_flipper }
    base.let(:app) { build_app(flipper) }
  end

  def build_app(flipper)
    Flipper::UI.app(flipper, secret: "test")
  end

  def build_flipper(adapter = build_memory_adapter)
    Flipper.new(adapter)
  end

  def build_memory_adapter
    Flipper::Adapters::Memory.new
  end

  def json_response
    JSON.load(last_response.body)
  end
end

RSpec.configure do |config|
  config.fail_fast = true

  config.include Rack::Test::Methods
  config.include SpecHelpers
end
