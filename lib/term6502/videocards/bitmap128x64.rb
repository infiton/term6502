# frozen_string_literal: true

module Term6502
  module Videocard
    class Bitmap128x64 < BaseVideocard
      COLORS = [
        [0,  0x00, 0x00, 0x00], # BLACK
        [1,  0xff, 0xff, 0xff], # WHITE
        [2,  0x88, 0x00, 0x00], # RED
        [3,  0xaa, 0xff, 0xee], # CYAN
        [4,  0xcc, 0x44, 0xcc], # PURPLE
        [5,  0x00, 0xcc, 0x55], # GREEN
        [6,  0x00, 0x00, 0xaa], # BLUE
        [7,  0xee, 0xee, 0x77], # YELLOW
        [8,  0xdd, 0x88, 0x55], # ORANGE
        [9,  0x66, 0x44, 0x00], # BROWN
        [10, 0xff, 0x77, 0x77], # LIGHT_RED
        [11, 0x33, 0x33, 0x33], # DARK_GREY
        [12, 0x77, 0x77, 0x77], # GREY
        [13, 0xaa, 0xff, 0x66], # LIGHT_GREEN
        [14, 0x00, 0x88, 0xff], # LIGHT_BLUE
        [15, 0xbb, 0xbb, 0xbb], # LIGHT_GREY
      ]

      COLOR_OFFSET = 214

      def lines
        64
      end

      def columns
        128
      end

      def setup(curses)
        @color_map = {}
        @original_color_map = {}

        COLORS.each do |color|
          color_idx, r, g, b = color
          curses_idx = color_idx + 1
          curses_color_idx = COLOR_OFFSET + color_idx

          @original_color_map[curses_color_idx] = curses.color_content(curses_color_idx)
          curses.init_color(curses_color_idx, curses_color(r), curses_color(g), curses_color(b))
          curses.init_pair(curses_idx, curses_color_idx, curses_color_idx)
        end
      end

      def restore(curses)
        return unless @original_color_map

        @original_color_map.each do |color, rgb|
          r, g, b = rgb
          curses.init_color(color, r, g, b)
        end
      end

      def draw(curses, window)
        lines.times do |line|
          Ruby6502.read(
            location: frame_buffer + (line * columns),
            bytes: columns
          ).each do |pixel|
            color = (pixel & 0xf) + 1

            window.attron(curses.color_pair(color)) { window << "\u2588" }
          end

          curses.clrtoeol
          window << "\n"
        end
      end
    end
  end
end
