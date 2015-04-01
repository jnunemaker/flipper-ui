require 'delegate'
require 'flipper/ui/decorators/gate'

module Flipper
  module UI
    module Decorators
      class Feature < SimpleDelegator
        # Public: The feature being decorated.
        alias_method :feature, :__getobj__

        # Public: Returns name titleized.
        def pretty_name
          @pretty_name ||= titleize(name)
        end

        # Public: Returns instance as hash that is ready to be json dumped.
        def as_json
          gate_values = feature.gate_values
          {
            'id' => name.to_s,
            'name' => pretty_name,
            'state' => state.to_s,
            'description' => description,
            'gates' => gates.map { |gate|
              Decorators::Gate.new(gate, gate_values[gate.key]).as_json
            },
          }
        end

        # Private
        def titleize(str)
          str.to_s.split('_').map { |word| word.capitalize }.join(' ')
        end
      end
    end
  end
end
