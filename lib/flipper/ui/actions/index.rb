require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Index < UI::Action

        route %r{.*}

        def get
          view_response :index
        end
      end
    end
  end
end
