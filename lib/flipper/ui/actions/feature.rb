require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Feature < UI::Action

        route %r{features/[^/]*/?\Z}

        def get
          feature_name = Rack::Utils.unescape(request.path.split("/").last)
          @feature = Decorators::Feature.new(flipper[feature_name])
          @page_title = "#{@feature.key} // Features"
          @percentages = [0, 1, 5, 10, 15, 25, 50, 75, 100]

          view_response :feature
        end
      end
    end
  end
end
