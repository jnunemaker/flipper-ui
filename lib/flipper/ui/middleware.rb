require 'pathname'
require 'erb'
require 'rack'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    class Middleware
      Error = Class.new(StandardError)

      def initialize(app, flipper)
        @app = app
        @flipper = flipper
      end

      module Helpers
        def h(str)
          Rack::Utils.escape_html(str)
        end
      end

      class Action
        Error = Class.new(Middleware::Error)
        MethodNotSupported = Class.new(Error)

        include Helpers

        def self.views_path
          @views_path ||= Flipper::UI.root.join('views')
        end

        def self.public_path
          @public_path ||= Flipper::UI.root.join('public')
        end

        attr_reader :flipper, :request

        def initialize(flipper, request)
          @flipper, @request = flipper, request
          @code = 200
          @headers = {'Content-Type' => 'text/html'}
        end

        def render(name)
          body = render_with_layout do
            render_without_layout name
          end

          Rack::Response.new(body, @code, @headers)
        end

        def render_with_layout(&block)
          render_template :layout, &block
        end

        def render_without_layout(name)
          render_template name
        end

        def render_template(name)
          path = views_path.join("#{name}.erb")
          contents = path.read
          compiled = ERB.new(contents)
          compiled.result Proc.new {}.binding
        end

        def views_path
          self.class.views_path
        end

        def public_path
          self.class.public_path
        end
      end

      class Index < Action
        Feature = Struct.new(:name)

        def get
          @features = flipper.features.map { |feature|
            Decorators::Feature.new(feature)
          }
          render :index
        end
      end

      class File < Action
        def get
          Rack::File.new(public_path).call(request.env)
        end
      end

      class Route
        def self.detect(request)
          return unless request.path_info =~ /^\/flipper/

          case request.path_info
          when /\/flipper\/?$/
            Index
          when /\/flipper\/images|css|js\/(.*)/
            File
          end
        end
      end

      def call(env)
        request = Rack::Request.new(env)

        if action_class = Route.detect(request)
          action = action_class.new(@flipper, request)
          method_name = request.request_method.downcase

          if action.respond_to?(method_name)
            action.send method_name
          else
            raise Action::MethodNotSupported, "#{action.class} does not support #{method_name}"
          end
        else
          @app.call(env)
        end
      end
    end
  end
end
