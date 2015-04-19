require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Index < UI::Action

        route %r{.*}

        def get
          redirect_to "/features"
        end
      end
    end
  end
end
