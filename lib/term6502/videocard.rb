# frozen_string_literal: true

module Term6502
  module Videocard
    class BaseVideocard
      include Peripheral

      def initialize(frame_buffer:)
        @frame_buffer = frame_buffer
      end

      def profile
        "term6502-#{type}"
      end

      def setup(curses); end

      def restore(curses); end

      private

      attr_reader :frame_buffer

      def curses_color(byte)
        ((byte * 200) / 51).to_i
      end
    end
  end
end

require "term6502/videocards/bitmap128x64"

module Term6502
  module Videocard
    VIDEOCARDS = {
      "bitmap128x64" => Bitmap128x64,
    }

    def self.types
      VIDEOCARDS.keys
    end

    def self.build(videocard_class:, frame_buffer:)
      raise "Unknown videocard #{videocard_class}." unless VIDEOCARDS[videocard_class]

      VIDEOCARDS[videocard_class].new(frame_buffer: frame_buffer)
    end
  end
end
