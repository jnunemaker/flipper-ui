# Nothing to see here... move along.
# Sets up load path for examples and requires some stuff
require 'pp'
require 'pathname'

root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'flipper-ui'
require 'flipper/adapters/memory'

adapter = Flipper::Adapters::Memory.new({})
flipper = Flipper.new(adapter)

use Flipper::UI::Middleware, flipper
run lambda { |env|
  [200, {'Content-Type' => 'text/html'}, ['Go here for <a href="/flipper">Flipper!</a>']]
}
