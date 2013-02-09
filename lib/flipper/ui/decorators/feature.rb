require 'delegate'

module Flipper
  module UI
    module Decorators
      class Feature < SimpleDelegator
        alias_method :feature, :__getobj__

        # Public: Returns name titleized.
        def pretty_name
          @pretty_name ||= titleize(name)
        end

        def as_json
          {
            'id' => name.to_s,
            'name' => pretty_name,
            'state' => state.to_s,
            'description' => description,
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
