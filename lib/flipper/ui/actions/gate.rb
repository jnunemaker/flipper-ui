require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Gate < UI::Action

        # Private: Struct to wrap actors so they can respond to flipper_id.
        FakeActor = Struct.new(:flipper_id)

        route %r{features/[^/]*/[^/]*/?\Z}

        def post
          feature_name, gate_name = request.path.split('/').pop(2).map{ |value| Rack::Utils.unescape value }
          update_gate_method_name = "update_#{gate_name}"

          feature = flipper[feature_name.to_sym]
          @feature = Decorators::Feature.new(feature)

          unless respond_to?(update_gate_method_name, true)
            update_gate_method_undefined(gate_name)
          end

          send(update_gate_method_name, feature)
          gate = feature.gate(gate_name)
          value = feature.gate_values[gate.key]

          redirect_to "/features/#{@feature.key}"
        end

        private

        def update_boolean(feature)
          if params["action"] == "Enable"
            feature.enable
          else
            feature.disable
          end
        end

        def update_actor(feature)
          value = params["value"]

          if Util.blank?(value)
            invalid_actor_value(value)
          end

          thing = FakeActor.new(value)

          case params["operation"]
          when "enable"
            feature.enable_actor thing
          when "disable"
            feature.disable_actor thing
          end
        end

        def update_group(feature)
          group_name = params["value"]

          case params["operation"]
          when "enable"
            feature.enable_group group_name
          when "disable"
            feature.disable_group group_name
          end
        rescue Flipper::GroupNotRegistered => e
          group_not_registered group_name
        end

        def update_percentage_of_actors(feature)
          value = params["value"]
          feature.enable_percentage_of_actors value
        rescue ArgumentError => exception
          invalid_percentage value, exception
        end

        def update_percentage_of_time(feature)
          value = params["value"]
          feature.enable_percentage_of_time value
        rescue ArgumentError => exception
          invalid_percentage value, exception
        end

        # Private: Returns error response for invalid actor value.
        def invalid_actor_value(value)
          error = Rack::Utils.escape("#{value.inspect} is not a valid actor value.")
          redirect_to("/features/#{@feature.key}?error=#{error}")
        end

        # Private: Returns error response that group was not registered.
        def group_not_registered(group_name)
          error = Rack::Utils.escape("The group named #{group_name.inspect} has not been registered.")
          redirect_to("/features/#{@feature.key}?error=#{error}")
        end

        # Private: Returns error response for invalid percentage value.
        def invalid_percentage(value, exception)
          error = Rack::Utils.escape("Invalid percentage of time value: #{exception.message}")
          redirect_to("/features/#{@feature.key}?error=#{error}")
        end

        # Private: Returns error response that gate update method is not defined.
        def update_gate_method_undefined(gate_name)
          error = Rack::Utils.escape("#{gate_name.inspect} gate does not exist therefore it cannot be updated.")
          redirect_to("/features/#{@feature.key}?error=#{error}")
        end
      end
    end
  end
end
