require 'forwardable'
require 'flipper/ui/error'
require 'flipper/ui/eruby'

module Flipper
  module UI
    class Action
      extend Forwardable

      # Public: Call this in subclasses so the action knows its route.
      #
      # regex - The Regexp that this action should run for.
      #
      # Returns nothing.
      def self.route(regex)
        @regex = regex
      end

      # Internal: Initializes and runs an action for a given request.
      #
      # flipper - The Flipper::DSL instance.
      # request - The Rack::Request that was sent.
      #
      # Returns result of Action#run (should be a Rack::Response usually).
      def self.run(flipper, request)
        new(flipper, request).run
      end

      # Internal: The regex that matches which routes this action will work for.
      def self.regex
        @regex || raise("#{name}.route is not set")
      end

      # Private: The path to the views folder.
      def self.views_path
        @views_path ||= Flipper::UI.root.join('views')
      end

      # Private: The path to the public folder.
      def self.public_path
        @public_path ||= Flipper::UI.root.join('public')
      end

      # Public: The instance of the Flipper::DSL the middleware was
      # initialized with.
      attr_reader :flipper

      # Public: The Rack::Request to provide a response for.
      attr_reader :request

      # Public: The params for the request.
      def_delegator :@request, :params

      def initialize(flipper, request)
        @flipper, @request = flipper, request
        @code = 200
        @headers = {'Content-Type' => 'text/html'}
      end

      def request_method_name
        @request_method_name ||= @request.request_method.downcase
      end

      # Public: Runs the request method for the provided request.
      #
      # Returns whatever the request method returns in the action.
      def run
        if respond_to?(request_method_name)
          send(request_method_name)
        else
          raise UI::RequestMethodNotSupported, "#{self.class} does not support request method #{request_method_name.inspect}"
        end
      end

      # Public: Runs another action from within the request method of a
      # different action.
      #
      # action_class - The class of the other action to run.
      #
      # Examples
      #
      #   run_other_action Index
      #   # => result of running Index action
      #
      # Returns result of other action.
      def run_other_action(action_class)
        action_class.new(flipper, request).run
      end

      def render(name)
        body = render_with_layout do
          render_without_layout name
        end

        Rack::Response.new(body, @code, @headers)
      end

      def render_json(object, options = {})
        body = MultiJson.dump(object)
        code = options.fetch(:code, @code)

        headers = @headers.merge({
          'Content-Type' => 'application/json',
        })

        Rack::Response.new(body, code, headers)
      end

      # Private
      def render_with_layout(&block)
        render_template :layout, &block
      end

      # Private
      def render_without_layout(name)
        render_template name
      end

      # Private
      def render_template(name)
        path = views_path.join("#{name}.erb")
        contents = path.read
        compiled = Eruby.new(contents)
        compiled.result Proc.new {}.binding
      end

      # Private
      def views_path
        self.class.views_path
      end

      # Private
      def public_path
        self.class.public_path
      end
    end
  end
end
