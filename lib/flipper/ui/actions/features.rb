require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Features < UI::Action

        route %r{features/?\Z}

        def get
          features = flipper.features.map { |feature|
            Decorators::Feature.new(feature)
          }.sort_by(&:pretty_name)

          json_response features.map(&:as_json)
        end
      end
    end
  end
end
