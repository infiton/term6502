# frozen_string_literal: true

require "singleton"
require "optparse"

require "term6502"

module Term6502
  class CLI
    include Singleton

    DEFAULT_OPTIONS = {
      debug: false,
      keyboard: "ps2",
      videocard: "bitmap128x64",
      program_location: 0x8000,
      frame_buffer: 0x2000,
      keyboard_port: 0x6001,
      tick_rate: 10000,
    }

    def parse(args = ARGV)
      opts = parse_options(args)

      @program_file = ARGV.shift
      raise "Must supply an executable file for the 6502" unless program_file

      update_options(opts)
    end

    def run
      ensure_compatible_terminal
      runner = Runner.new(
        program: program,
        program_location: options[:program_location],
        keyboard: keyboard,
        videocard: videocard,
        tick_rate: options[:tick_rate],
        debug: debug?
      )

      runner.run
    end

    private

    attr_reader :program_file

    def ensure_compatible_terminal
      unless ENV["TERM_PROGRAM"] == "iTerm.app"
        raise "Term6502 currently only runs reliably in iTerm"
      end

      true
    end

    def debug?
      !!options[:debug]
    end

    def program
      File.open(program_file).each_byte.to_a
    end

    def keyboard
      Keyboard.build(
        keyboard_class: options[:keyboard],
        port: options[:keyboard_port],
      )
    end

    def videocard
      Videocard.build(
        videocard_class: options[:videocard],
        frame_buffer: options[:frame_buffer],
      )
    end

    def options
      @options ||= DEFAULT_OPTIONS.dup
    end

    def update_options(opts)
      @options = options.merge(opts)
    end

    def parse_options(args)
      options = {}

      OptionParser.new do |parser|
        parser.banner = "Usage: term6502 PROGRAM [options]"
        parser.on("--debug", "Starts the emulator in DEBUG mode.") do
          options[:debug] = true
        end

        parser.on("--program_location PROGRAM_LOCATION", "Memory location of load program.") do |program_location|
          options[:program_location] = program_location.to_i(16)
        end

        parser.on("--keyboard KEYBOARD", "Keyboard to emulate: #{Keyboard.types.join(",")}.") do |keyboard|
          options[:keyboard] = keyboard
        end

        parser.on("--keyboard_port KEYBOARDPORT", "Memory location of the keyboard.") do |keyboard_port|
          options[:keyboard_port] = keyboard_port.to_i(16)
        end

        parser.on("--videocard VIDEOCARD", "Video card to emulate: #{Videocard.types.join(",")}.") do |videocard|
          options[:videocard] = videocard
        end

        parser.on("--frame_buffer FRAMEBUFFER", "Location of the start of the frame buffer.") do |frame_buffer|
          options[:frame_buffer] = frame_buffer.to_i(16)
        end

        parser.on("--tick_rate TICKRATE", "Number of 6502 ticks per screen draw.") do |tick_rate|
          options[:tick_rate] = tick_rate.to_i
        end

        parser.on("-h", "--help", "Prints this help") do
          puts parser
          exit(0)
        end
      end.parse!

      options
    end
  end
end
