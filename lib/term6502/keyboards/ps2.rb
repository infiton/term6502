# frozen_string_literal: true

module Term6502
  module Keyboard
    class Ps2 < BaseKeyboard
      SCANCODES = {
        "`" => [0x0e],
        "~" => [0x0e, :shift],
        "1" => [0x16],
        "!" => [0x16, :shift],
        "2" => [0x1e],
        "@" => [0x1e, :shift],
        "3" => [0x26],
        "#" => [0x26, :shift],
        "4" => [0x25],
        "$" => [0x25, :shift],
        "5" => [0x2e],
        "%" => [0x2e, :shift],
        "6" => [0x36],
        "^" => [0x36, :shift],
        "7" => [0x3d],
        "&" => [0x3d, :shift],
        "8" => [0x3e],
        "*" => [0x3e, :shift],
        "9" => [0x46],
        "(" => [0x46, :shift],
        "0" => [0x45],
        ")" => [0x45, :shift],
        "-" => [0x4e],
        "_" => [0x4e, :shift],
        "=" => [0x55],
        "+" => [0x55, :shift],
        127 => [0x66], # curses backspace
        9 => [0x0d], # curses tab
        "q" => [0x15],
        "Q" => [0x15, :shift],
        "w" => [0x1d],
        "W" => [0x1d, :shift],
        "e" => [0x24],
        "E" => [0x24, :shift],
        "r" => [0x2d],
        "R" => [0x2d, :shift],
        "t" => [0x2c],
        "T" => [0x2c, :shift],
        "y" => [0x35],
        "Y" => [0x35, :shift],
        "u" => [0x3c],
        "U" => [0x3c, :shift],
        "i" => [0x43],
        "I" => [0x43, :shift],
        "o" => [0x44],
        "O" => [0x44, :shift],
        "p" => [0x4d],
        "P" => [0x4d, :shift],
        "[" => [0x54],
        "{" => [0x54, :shift],
        "]" => [0x5b],
        "}" => [0x5b, :shift],
        "\\" => [0x5d],
        "|" => [0x5d, :shift],
        # need a solution for Caps Lock
        "a" => [0x1c],
        "A" => [0x1c, :shift],
        "s" => [0x1b],
        "S" => [0x1b, :shift],
        "d" => [0x23],
        "D" => [0x23, :shift],
        "f" => [0x2b],
        "F" => [0x2b, :shift],
        "g" => [0x34],
        "G" => [0x34, :shift],
        "h" => [0x33],
        "H" => [0x33, :shift],
        "j" => [0x3b],
        "J" => [0x3b, :shift],
        "k" => [0x42],
        "K" => [0x42, :shift],
        "l" => [0x4b],
        "L" => [0x4b, :shift],
        ";" => [0x4c],
        ":" => [0x4c, :shift],
        "'" => [0x52],
        "\"" => [0x52, :shift],
        10 => [0x5a],
        "z" => [0x1a],
        "Z" => [0x1a, :shift],
        "x" => [0x22],
        "X" => [0x22, :shift],
        "c" => [0x21],
        "C" => [0x21, :shift],
        "v" => [0x2a],
        "V" => [0x2a, :shift],
        "b" => [0x32],
        "B" => [0x32, :shift],
        "n" => [0x31],
        "N" => [0x31, :shift],
        "m" => [0x3a],
        "M" => [0x3a, :shift],
        "," => [0x41],
        "<" => [0x41, :shift],
        "." => [0x49],
        ">" => [0x49, :shift],
        "/" => [0x4a],
        "?" => [0x4a, :shift],
        " " => [0x29],
        259 => [0x75, :extended], # up arrow
        260 => [0x6b, :extended], # left arrow
        258 => [0x72, :extended], # down arrow
        261 => [0x74, :extended], # right arrow
      }

      SHIFT_SCANCODE = 0x12
      RELEASE_SCANCODE = 0xf0
      EXTENDED_SCANCODE = 0xe0

      SCANCODE_SEQUENCES = {}
      SCANCODES.each do |char, scancode|
        codebyte, option = scancode
        SCANCODE_SEQUENCES[char] = if option == :shift
          [
            SHIFT_SCANCODE,
            codebyte,
            RELEASE_SCANCODE,
            codebyte,
            RELEASE_SCANCODE,
            SHIFT_SCANCODE,
          ]
        elsif option == :extended
          [
            EXTENDED_SCANCODE,
            codebyte,
            EXTENDED_SCANCODE,
            RELEASE_SCANCODE,
            codebyte,
          ]
        else
          [
            codebyte,
            RELEASE_SCANCODE,
            codebyte,
          ]
        end
      end

      TICKS_BETWEEN_BYTES = 100

      def press(curses_key)
        scancode_sequence = SCANCODE_SEQUENCES[curses_key]

        return unless scancode_sequence

        scancode_sequence.each do |byte|
          queue << byte
          TICKS_BETWEEN_BYTES.times { queue << 0 }
        end
      end

      def tick(ticks)
        ticks.times do
          byte = queue.pop(true)

          next if byte == 0

          @asserting = true
          Ruby6502.register_read_write_hook(port, :read_write) do
            @asserting = false

            Ruby6502.deregister_read_write_hook(port, :read_write)
          end

          Ruby6502.load([byte], location: port)
        end
      rescue ThreadError
        # queue is empty
      end
    end
  end
end
