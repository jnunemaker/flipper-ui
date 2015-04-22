require 'flipper/ui/util'
require 'flipper/ui/action'
require 'flipper/ui/actor'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class GatesApi < UI::Action
        route %r{api/features/.*/.*/?\Z}

        def post
          feature_name, gate_name = request.path.split('/').pop(2).map{ |value| Rack::Utils.unescape value }
          update_gate_method_name = "update_#{gate_name}"

          unless respond_to?(update_gate_method_name)
            update_gate_method_undefined(gate_name)
          end

          feature = flipper[feature_name.to_sym]
          send(update_gate_method_name, feature)
          gate = feature.gate(gate_name)
          value = feature.gate_values[gate.key]

          json_response Decorators::Gate.new(gate, value).as_json
        end

        def update_boolean(feature)
          if params['value'] == 'true'
            feature.enable
          else
            feature.disable
          end
        end

        def update_actor(feature)
          value = params['value']

          if Util.blank?(value)
            invalid_actor_value(value)
          end

          actor = Flipper::UI::Actor.new(value)

          case params['operation']
          when 'enable'
            feature.enable actor
          when 'disable'
            feature.disable actor
          end
        end

        def update_group(feature)
          group_name = params['value']
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

        def update_percentage_of_actors(feature)
          value = params['value']
          feature.enable_percentage_of_actors value
        rescue ArgumentError => exception
          invalid_percentage value, exception
        end

        def update_percentage_of_time(feature)
          value = params['value']
          feature.enable_percentage_of_time value
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
          response = {status: 'error'}

          if Util.blank?(group_name)
            status 422
            response[:message] = "Group name is required."
          else
            status 404
            response[:message] = "The group named #{group_name.inspect} has not been registered."
          end

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
