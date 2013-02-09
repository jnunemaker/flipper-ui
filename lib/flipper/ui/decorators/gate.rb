require 'delegate'

module Flipper
  module UI
    module Decorators
      class Gate < SimpleDelegator
        alias_method :gate, :__getobj__

        def as_json
          {
            'key' => gate.key.to_s,
            'name' => gate.name.to_s,
            'value' => gate.value,
          }
        end
      end
    end
  end
end
