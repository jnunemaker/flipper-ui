#
# Usage:
#   bundle exec rackup examples/basic.ru
#   http://localhost:9292/
#
require 'pp'
require 'logger'
require 'pathname'

root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'flipper-ui'
require 'flipper/adapters/memory'

Flipper.register(:admins) { |actor|
  actor.respond_to?(:admin?) && actor.admin?
}

Flipper.register(:early_access) { |actor|
  actor.respond_to?(:early?) && actor.early?
}

# Setup logging of flipper calls.
require 'flipper/instrumentation/log_subscriber'
Flipper::Instrumentation::LogSubscriber.logger = Logger.new(STDOUT)

adapter = Flipper::Adapters::Memory.new({})
flipper = Flipper.new(adapter, :instrumenter => ActiveSupport::Notifications)

Actor = Struct.new(:flipper_id)

flipper[:search_performance_another_long_thing].enable
flipper[:gauges_tracking].enable
flipper[:unused].disable
flipper[:suits].enable Actor.new('1')
flipper[:suits].enable Actor.new('6')
flipper[:secrets].enable flipper.group(:admins)
flipper[:secrets].enable flipper.group(:early_access)
flipper[:logging].enable flipper.time(5)
flipper[:new_cache].enable flipper.actors(15)

run Flipper::UI.app(flipper)
