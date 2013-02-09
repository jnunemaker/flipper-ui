require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Gate < UI::Action

        route %r{^/flipper/features/.*/.*/?$}

        # Get should run the index route. All the url does is control what is
        # opened and closed when the page is loaded.
        def get
          Index.new(flipper, request).get
        end

        # FIXME: Handle gate not found by name.
        # FIXME: Handle gate updates other than boolean.
        def post
          _, _, _, feature_name, gate_name = request.path.split('/')

          feature = flipper[feature_name.to_sym]
          gate = feature.gate(gate_name)

          method_name = "update_#{gate_name}"

          if respond_to?(method_name)
            send(method_name, feature, gate)
          else
            # TODO: raise error probably or output error message
          end

          decorated_gate = Decorators::Gate.new(gate)
          render_json decorated_gate.as_json
        end

        def update_boolean(feature, gate)
          if params['value'] == 'true'
            feature.enable
          else
            feature.disable
          end
        end

        def update_actors
          raise 'soon...'
        end

        def update_groups
          raise 'soon...'
        end

        def update_percentage_of_actors
          raise 'soon...'
        end

        def update_percentage_of_random
          raise 'soon...'
        end
      end
    end
  end
end
