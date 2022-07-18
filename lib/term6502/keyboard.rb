# frozen_string_literal: true

module Term6502
  module Keyboard
    class BaseKeyboard
      def initialize(port:)
        @port = port
        @asserting = false
        @queue = Queue.new
      end

      def type
        self.class.name.split("::").last.downcase
      end

      def asserting?
        @asserting
      end

      def tick(ticks)
      end

      def press(curses_key)
        raise NotImplementedError, "keyboard #{type} has not implemented press"
      end

      private

      attr_reader :port, :queue
    end
  end
end

require "term6502/keyboards/ps2"

module Term6502
  module Keyboard
    KEYBOARDS = {
      "ps2" => Ps2,
    }

    def self.types
      KEYBOARDS.keys
    end

    def self.build(keyboard_class:, port:)
      raise "Unknown keyboard #{keyboard_class}." unless KEYBOARDS[keyboard_class]

      KEYBOARDS[keyboard_class].new(port: port)
    end
  end
end
