require 'rack'
require 'flipper/ui/action_collection'

# Require all actions automatically.
Flipper::UI.root.join('actions').each_child(false) do |name|
  require "flipper/ui/actions/#{name}"
end

module Flipper
  module UI
    class Middleware
      # Public: Initializes an instance of the UI middleware.
      #
      # app - The app this middleware is included in.
      # flipper_or_block - The Flipper::DSL instance or a block that yields a
      #                    Flipper::DSL instance to use for all operations.
      #
      # Examples
      #
      #   flipper = Flipper.new(...)
      #
      #   # using with a normal flipper instance
      #   use Flipper::UI::Middleware, flipper
      #
      #   # using with a block that yields a flipper instance
      #   use Flipper::UI::Middleware, lambda { Flipper.new(...) }
      #
      def initialize(app, flipper_or_block)
        @app = app

        if flipper_or_block.respond_to?(:call)
          @flipper_block = flipper_or_block
        else
          @flipper = flipper_or_block
        end

        @action_collection = ActionCollection.new
        @action_collection.add UI::Actions::File
        @action_collection.add UI::Actions::Features
        @action_collection.add UI::Actions::Gate

        # Catch all, always last.
        @action_collection.add UI::Actions::Index
      end

      def flipper
        @flipper ||= @flipper_block.call
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        request = Rack::Request.new(env)
        action_class = @action_collection.action_for_request(request)

        if action_class.nil?
          @app.call(env)
        else
          action_class.run(flipper, request)
        end
      end
    end
  end
end
