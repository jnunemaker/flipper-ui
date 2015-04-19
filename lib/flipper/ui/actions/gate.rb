require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'

module Flipper
  module UI
    module Actions
      class Gate < UI::Action
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

        # Private: Returns error response that gate update method is not defined.
        def update_gate_method_undefined(gate_name)
          error = Rack::Utils.escape("#{gate_name.inspect} gate does not exist therefore it cannot be updated.")
          redirect_to("/features/#{@feature.key}?error=#{error}")
        end
      end
    end
  end
end
