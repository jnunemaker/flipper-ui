#
# Usage: bundle exec rackup examples/basic.ru
#
# Visit: http://localhost:9292/flipper in browser.
require 'pp'
require 'pathname'

root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'flipper-ui'
require 'flipper/adapters/memory'

Flipper.register(:admins) { |actor| actor.admin? }

adapter = Flipper::Adapters::Memory.new({})
flipper = Flipper.new(adapter)

flipper[:search_performance].enable
flipper[:gauges_tracking].enable
flipper[:secrets].enable flipper.group(:admins)
flipper[:logging].enable flipper.random(5)
flipper[:new_cache].enable flipper.actors(15)

use Flipper::UI::Middleware, flipper
run lambda { |env|
  [200, {'Content-Type' => 'text/html'}, ['Go here for <a href="/flipper">Flipper!</a>']]
}
