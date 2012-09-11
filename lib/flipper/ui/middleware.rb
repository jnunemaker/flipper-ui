require 'pathname'
require 'erb'
require 'rack'

module Flipper
  module UI
    class Middleware
      def initialize(app, flipper)
        @app = app
        @flipper = flipper
      end

      class Action
        def self.views_path
          Flipper::UI.root.join('views')
        end

        def self.public_path
          Flipper::UI.root.join('public')
        end

        attr_reader :request

        def initialize(request)
          @request = request
          @code = 200
          @headers = {'Content-Type' => 'text/html'}
        end

        def render(name)
          body = render_with_layout do
            render_without_layout name
          end

          Rack::Response.new(body)
        end

        def render_with_layout(&block)
          render_template :layout, &block
        end

        def render_without_layout(name)
          render_template name
        end

        def render_template(name)
          path = self.class.views_path.join("#{name}.erb")
          contents = path.read
          compiled = ERB.new(contents)
          compiled.result Proc.new {}.binding
        end
      end

      class Index < Action
        def get
          render :index
        end
      end

      class File < Action
        def get
          Rack::File.new(self.class.public_path).call(request.env)
        end
      end

      class Route
        def self.detect(request)
          return unless request.path_info =~ /^\/flipper/

          case request.path_info
          when /\/flipper\/?$/
            Index.new(request)
          when /\/flipper\/images\/(.*)/
            File.new(request)
          when /\/flipper\/css\/(.*)/
            File.new(request)
          end
        end
      end

      def call(env)
        request = Rack::Request.new(env)

        if action = Route.detect(request)
          case request.request_method.downcase
          when 'get'
            action.get
          else
            raise "#{request.request_method} not supported at this time"
          end
        else
          @app.call(env)
        end
      end
    end
  end
end
