require 'rack'
require 'flipper/ui/action_collection'

# Require all actions automatically.
Flipper::UI.root.join('actions').each_child(false) do |name|
  require "flipper/ui/actions/#{name}"
end

module Flipper
  module UI
    class Middleware
      def initialize(app, flipper)
        @app = app
        @flipper = flipper

        @action_collection = ActionCollection.new
        @action_collection.add UI::Actions::Index
        @action_collection.add UI::Actions::Features
        @action_collection.add UI::Actions::File
      end

      def call(env)
        request = Rack::Request.new(env)
        action_class = @action_collection.action_for_request(request)

        if action_class.nil?
          @app.call(env)
        else
          action_class.run(@flipper, request)
        end
      end
    end
  end
end
