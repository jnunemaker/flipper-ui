module Flipper
  module UI
    module Util
      # Private: 0x3000: fullwidth whitespace
      NON_WHITESPACE_REGEXP = %r![^\s#{[0x3000].pack("U")}]!

      def self.blank?(str)
        str.to_s !~ NON_WHITESPACE_REGEXP
      end
    end
  end
end
