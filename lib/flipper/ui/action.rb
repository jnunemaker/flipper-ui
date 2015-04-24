require 'forwardable'
require 'flipper/ui/error'
require 'flipper/ui/eruby'
require 'json'

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
      # Returns result of Action#run.
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
        @headers = {"Content-Type" => "text/plain"}
        @breadcrumbs = []
      end

      # Public: Runs the request method for the provided request.
      #
      # Returns whatever the request method returns in the action.
      def run
        if respond_to?(request_method_name)
          catch(:halt) { send(request_method_name) }
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
      #   run_other_action Home
      #   # => result of running Home action
      #
      # Returns result of other action.
      def run_other_action(action_class)
        action_class.new(flipper, request).run
      end

      # Public: Call this with a response to immediately stop the current action
      # and respond however you want.
      #
      # response - The response you would like to return.
      def halt(response)
        throw :halt, response
      end

      # Public: Compiles a view and returns rack response with that as the body.
      #
      # name - The Symbol name of the view.
      #
      # Returns a response.
      def view_response(name)
        header "Content-Type", "text/html"
        body = view_with_layout { view_without_layout name }
        halt [@code, @headers, [body]]
      end

      # Public: Dumps an object as json and returns rack response with that as
      # the body. Automatically sets Content-Type to "application/json".
      #
      # object - The Object that should be dumped as json.
      #
      # Returns a response.
      def json_response(object)
        header 'Content-Type', 'application/json'
        body = JSON.dump(object)
        halt [@code, @headers, [body]]
      end

      # Public: Redirect to a new location.
      #
      # location - The String location to set the Location header to.
      def redirect_to(location)
        status 302
        header "Location", "#{script_name}#{location}"
        halt [@code, @headers, [""]]
      end

      # Public: Set the status code for the response.
      #
      # code - The Integer code you would like the response to return.
      def status(code)
        @code = code.to_i
      end

      # Public: Set a header.
      #
      # name - The String name of the header.
      # value - The value of the header.
      def header(name, value)
        @headers[name] = value
      end

      class Breadcrumb
        attr_reader :text, :href

        def initialize(text, href = nil)
          @text = text
          @href = href
        end

        def active?
          @href.nil?
        end
      end

      # Public: Add a breadcrumb to the trail.
      #
      # text - The String text for the breadcrumb.
      # href - The String href for the anchor tag (optional). If nil, breadcrumb
      #        is assumed to be the end of the trail.
      def breadcrumb(text, href = nil)
        @breadcrumbs << Breadcrumb.new(text, href)
      end

      # Private
      def view_with_layout(&block)
        view :layout, &block
      end

      # Private
      def view_without_layout(name)
        view name
      end

      # Private
      def view(name)
        path = views_path.join("#{name}.erb")

        unless path.exist?
          raise "Template does not exist: #{path}"
        end

        contents = path.read
        compiled = Eruby.new(contents)
        compiled.result Proc.new {}.binding
      end

      # Internal: The path the app is mounted at.
      def script_name
        request.env['SCRIPT_NAME']
      end

      # Private
      def views_path
        self.class.views_path
      end

      # Private
      def public_path
        self.class.public_path
      end

      # Private: Returns the request method converted to an action method.
      def request_method_name
        @request_method_name ||= @request.request_method.downcase
      end

      def csrf_input_tag
        %Q(<input type="hidden" name="authenticity_token" value="#{@request.session[:csrf]}">)
      end
    end
  end
end
