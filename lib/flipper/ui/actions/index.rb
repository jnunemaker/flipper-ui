require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Index < UI::Action

        route /^\/flipper\/?$/

        def get
          @features = flipper.features.map { |feature|
            Decorators::Feature.new(feature)
          }
          render :index
        end
      end
    end
  end
end
