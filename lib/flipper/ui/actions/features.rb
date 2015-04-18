require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Features < UI::Action

        route %r{features/?\Z}

        def get
          @page_title = "Features"
          features = flipper.features.map { |feature|
            Decorators::Feature.new(feature)
          }.group_by { |feature| feature.state }

          @enabled = Array(features[:on]).sort_by(&:pretty_name)
          @disabled = Array(features[:off]).sort_by(&:pretty_name)
          @conditional = Array(features[:conditional]).sort_by(&:pretty_name)

          @show_blank_slate = features.empty?

          view_response :features
        end
      end
    end
  end
end
