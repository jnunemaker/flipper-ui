require 'delegate'

module Flipper
  module UI
    module Decorators
      class Gate < SimpleDelegator
        # Public: The gate being decorated.
        alias_method :gate, :__getobj__

        # Public: The value for the gate from the adapter.
        attr_reader :value

        def initialize(gate, value = nil)
          super gate
          @value = value
        end

        # Public: Returns instance as hash that is ready to be json dumped.
        def as_json
          {
            'key' => gate.key.to_s,
            'name' => gate.name.to_s,
            'value' => @value,
          }
        end
      end
    end
  end
end
