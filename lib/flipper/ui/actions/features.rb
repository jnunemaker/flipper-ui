require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Features < UI::Action

        route /^\/flipper\/features\/?$/

        def get
          features = flipper.features.map { |feature|
            Decorators::Feature.new(feature)
          }

          render_json features.map(&:as_json)
        end
      end
    end
  end
end
