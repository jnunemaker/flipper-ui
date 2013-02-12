require 'rack/file'
require 'flipper/ui/action'

module Flipper
  module UI
    module Actions
      class File < UI::Action

        route %r{^/flipper/(images|css|js)/.*$}

        def get
          Rack::File.new(public_path).call(request.env)
        end
      end
    end
  end
end
