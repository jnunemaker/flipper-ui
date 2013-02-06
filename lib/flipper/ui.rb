require 'pathname'
require 'flipper'

module Flipper
  module UI
    def self.root
      @root ||= Pathname(__FILE__).dirname.expand_path.join('ui')
    end
  end
end

require 'flipper/ui/middleware'
