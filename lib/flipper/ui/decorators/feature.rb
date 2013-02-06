require 'delegate'

module Flipper
  module UI
    module Decorators
      class Feature < SimpleDelegator
        alias_method :feature, :__getobj__

        def html_id
          @html_id ||= name.to_s.gsub('_', '-').squeeze('-')
        end

        def pretty_name
          @pretty_name ||= titleize(name)
        end

        # Private
        def titleize(str)
          str.to_s.split('_').map { |word| word.capitalize }.join(' ')
        end
      end
    end
  end
end
