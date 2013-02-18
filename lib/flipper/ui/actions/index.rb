require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Index < UI::Action

        route %r{^/flipper.*$}

        def get
          @features = flipper.features.map { |feature|
            gate_values = flipper.adapter.get(feature)
            Decorators::Feature.new(feature, gate_values)
          }

          view_response :index
        end
      end
    end
  end
end
