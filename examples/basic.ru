#
# Usage:
#   bundle exec rackup examples/basic.ru
#   http://localhost:9292/flipper
#
# OR, you can use shotgun to get auto-reloading.
#
# Shotgun Usage:
#   bundle exec shotgun examples/basic.ru
#   http://localhost:9393/flipper
#
require 'pp'
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

adapter = Flipper::Adapters::Memory.new({})
flipper = Flipper.new(adapter)

Actor = Struct.new(:flipper_id)

flipper[:search_performance].enable
flipper[:gauges_tracking].enable
flipper[:unused].disable
flipper[:suits].enable Actor.new('1')
flipper[:suits].enable Actor.new('6')
flipper[:secrets].enable flipper.group(:admins)
flipper[:secrets].enable flipper.group(:early_access)
flipper[:logging].enable flipper.random(5)
flipper[:new_cache].enable flipper.actors(15)

use Flipper::UI::Middleware, flipper
run lambda { |env|
  [200, {'Content-Type' => 'text/html'}, ['Go here for <a href="/flipper">Flipper!</a>']]
}
