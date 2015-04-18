require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Index < UI::Action

        route %r{.*}

        def get
          status 302
          header "Location", "/features"
          [@code, @headers, [""]]
        end
      end
    end
  end
end
