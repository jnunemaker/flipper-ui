require 'flipper/ui/util'
require 'flipper/ui/action'
require 'flipper/ui/actions/index'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Gate < UI::Action

        # Private: Struct to wrap actors so they can respond to flipper_id.
        FakeActor = Struct.new(:flipper_id)

        route %r{features/.*/.*/?\Z}

        # Get should run the index route. All the url does is control what is
        # opened and closed when the page is loaded.
        def get
          run_other_action Index
        end

        # FIXME: Handle gate not found by name.
        # FIXME: Return more than just the gate as json response?
        def post
          feature_name, gate_name = request.path.split('/').pop(2).map{|value| Rack::Utils.unescape value }
          update_gate_method_name = "update_#{gate_name}"

          unless respond_to?(update_gate_method_name)
            update_gate_method_undefined(gate_name)
          end

          feature = flipper[feature_name.to_sym]
          send(update_gate_method_name, feature)
          gate = feature.gate(gate_name)
          gate_values = flipper.adapter.get(feature)
          value = gate_values[gate.key]

          json_response Decorators::Gate.new(gate, value).as_json
        end

        def update_boolean(feature)
          if params['value'] == 'true'
            feature.enable
          else
            feature.disable
          end
        end

        # FIXME: protect against invalid operations
        # FIXME: protect against invalid values (blank, empty, etc)
        def update_actor(feature)
          value = params['value']

          if Util.blank?(value)
            invalid_actor_value(value)
          end

          thing = FakeActor.new(value)
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
        def update_group(feature)
          group_name = params['value'].to_sym
          group = flipper.group(group_name)

          case params['operation']
          when 'enable'
            feature.enable group
          when 'disable'
            feature.disable group
          end
        rescue Flipper::GroupNotRegistered => e
          group_not_registered group_name
        end

        # FIXME: guard against percentage that doesn't fit 0 <= p <= 100
        def update_percentage_of_actors(feature)
          value = (params['value'] || 0).to_i
          feature.enable flipper.actors(value)
        rescue ArgumentError => exception
          invalid_percentage value, exception
        end

        # FIXME: guard against percentage that doesn't fit 0 <= p <= 100
        def update_percentage_of_random(feature)
          value = (params['value'] || 0).to_i
          feature.enable flipper.random(value)
        rescue ArgumentError => exception
          invalid_percentage value, exception
        end

        # Private: Returns error response for invalid actor value.
        def invalid_actor_value(value)
          response = {
            status: 'error',
            message: "#{value.inspect} is not a valid actor value.",
          }

          status 422
          halt json_response(response)
        end

        # Private: Returns error response for invalid percentage value.
        def invalid_percentage(value, exception)
          response = {
            status: 'error',
            message: exception.message,
          }

          status 422
          halt json_response(response)
        end

        # Private: Returns error response that group was not registered.
        def group_not_registered(group_name)
          response = {
            status: 'error',
            message: "The group named #{group_name.inspect} has not been registered.",
          }

          status 404
          halt json_response(response)
        end

        # Private: Returns error response that gate update method is not defined.
        def update_gate_method_undefined(gate_name)
          response = {
            status: 'error',
            message: "I have no clue how to update the gate named #{gate_name.inspect}.",
          }

          status 404
          halt json_response(response)
        end
      end
    end
  end
end
