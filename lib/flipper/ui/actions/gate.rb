require 'flipper/ui/action'
require 'flipper/ui/actions/index'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Gate < UI::Action

        route %r{^/flipper/features/.*/.*/?$}

        # Get should run the index route. All the url does is control what is
        # opened and closed when the page is loaded.
        def get
          run_other_action Index
        end

        # FIXME: Handle gate not found by name.
        # FIXME: Return more than just the gate as json response?
        def post
          _, _, _, feature_name, gate_name = request.path.split('/')

          feature = flipper[feature_name.to_sym]
          gate = feature.gate(gate_name)
          method_name = "update_#{gate_name}"

          if respond_to?(method_name)
            send(method_name, feature, gate)
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

        # FIXME: protect against invalid operations
        # FIXME: protect against invalid values (blank, empty, etc)
        def update_actor(feature, gate)
          thing = Struct.new(:flipper_id).new(params['value'])
          actor = flipper.actor(thing)

          case params['operation']
          when 'enable'
            feature.enable actor
          when 'disable'
            feature.disable actor
          end
        end

        # FIXME: protect against invalid operations
        # FIXME: protect against invalid values (blank, empty, etc)
        def update_group(feature, gate)
          group_name = params['value'].to_sym
          group = flipper.group(group_name)

          case params['operation']
          when 'enable'
            feature.enable group
          when 'disable'
            feature.disable group
          end
        end

        # FIXME: guard against percentage that doesn't fit 0 <= p <= 100
        def update_percentage_of_actors(feature, gate)
          value = (params['value'] || 0).to_i
          feature.enable flipper.actors(value)
        end

        # FIXME: guard against percentage that doesn't fit 0 <= p <= 100
        def update_percentage_of_random(feature, gate)
          value = (params['value'] || 0).to_i
          feature.enable flipper.random(value)
        end
      end
    end
  end
end
