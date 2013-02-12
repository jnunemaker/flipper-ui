require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Index < UI::Action

        route %r{^/flipper.*$}

        def get
          @features = flipper.features.map { |feature|
            Decorators::Feature.new(feature)
          }

          view_response :index
        end
      end
    end
  end
end
