require 'pathname'
require 'flipper'
require 'multi_json'

module Flipper
  module UI
    def self.root
      @root ||= Pathname(__FILE__).dirname.expand_path.join('ui')
    end

    def self.app(flipper)
      app = lambda { |env| [200, {'Content-Type' => 'text/html'}, ['']] }
      builder = Rack::Builder.new
      yield builder if block_given?
      builder.use Middleware, flipper
      builder.run app
      builder
    end
  end
end

require 'flipper/ui/middleware'
