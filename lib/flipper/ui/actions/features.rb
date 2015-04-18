require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Features < UI::Action

        route %r{features/?\Z}

        def get
          @page_title = "Features"
          @features = flipper.features.map { |feature|
            Decorators::Feature.new(feature)
          }.sort_by(&:pretty_name)

          view_response :features
        end
      end
    end
  end
end
