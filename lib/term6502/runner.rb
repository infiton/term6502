# frozen_string_literal: true

require "io/console"
require "curses"

module Term6502
  class Runner
    LINE_PADDING = 1
    COLUMN_PADDING = 2
    INFO_LINES = 25

    MEMORY_MAP_INDENT = 36
    MEMORY_MAP_WIDTH = 0x10

    UNKNOWN_COMMAND_MSG = "UNKNOWN COMMAND"

    def initialize(program:, program_location:, keyboard:, videocard:, random_byte_port:, tick_rate:, debug:)
      @program = program
      @program_location = program_location
      @keyboard = keyboard
      @videocard = videocard
      @tick_rate = tick_rate
      @random_byte_port = random_byte_port
      @debug = debug

      @memory_map_start = nil
      @memory_map_bytes = nil

      @unknown_command = false
      @debug_buffer = ""

      @delta_instructions = 0
      @delta_time = 0.0
    end

    def run
      initialize_terminal
      videocard.setup(Curses)

      Ruby6502.load(
        program,
        location: program_location,
      )

      Ruby6502.configure_rng(random_byte_port) if random_byte_port

      Ruby6502.reset

      last_instruction_count = Ruby6502.instruction_count
      last_time = Time.now

      loop do
        @delta_instructions = Ruby6502.instruction_count - last_instruction_count
        @delta_time = Time.now - last_time

        last_instruction_count = Ruby6502.instruction_count
        last_time = Time.now

        @window.setpos(0, 0)
        videocard.draw(Curses, @window)

        @window.setpos(videocard.lines, 0)
        draw_info

        @window.setpos(@window.maxy - 1, 0)
        @window.deleteln
        if debug?
          debug_str = @unknown_command ? UNKNOWN_COMMAND_MSG : @debug_buffer
          @window.addstr(":#{debug_str}")
        end

        @window.refresh

        key = @window.getch
        debug? ? debug_step(key) : step(key)
      end
    ensure
      videocard.restore(Curses)
      restore_terminal
    end

    private

    attr_reader :program, :program_location, :keyboard, :videocard, :random_byte_port, :tick_rate, :window

    def peripherals
      [keyboard, videocard]
    end

    def interrupt_asserted?
      peripherals.map(&:asserting?).any?
    end

    def peripheral_needs_timing?
      peripherals.map(&:needs_timing?).any?
    end

    def step_6502
      start_ticks = Ruby6502.tick_count
      Ruby6502.interrupt_request if interrupt_asserted?

      Ruby6502.step
      elapsed_ticks = Ruby6502.tick_count - start_ticks

      peripherals.each { |peripheral| peripheral.tick(elapsed_ticks) }

      elapsed_ticks
    end

    def step(key)
      case key
      when 27 # ESC
        @debug = true
        set_debug_state
      else
        keyboard.press(key)
      end

      if peripheral_needs_timing?
        ticks = tick_rate
        ticks -= step_6502 while ticks > 0
      else
        Ruby6502.exec(tick_rate)
      end
    end

    def debug_step(key)
      @unknown_command = false

      case key.to_s
      when Curses::KEY_RIGHT.to_s
        step_6502
      when "10"
        execute_command
      when "127", Curses::KEY_BACKSPACE.to_s
        @debug_buffer = @debug_buffer.chop
      else
        @debug_buffer += key.to_s
      end
    end

    def show_memory_map?
      !!(@memory_map_start && @memory_map_bytes)
    end

    def info_header
      header = ("\n" * 2)

      header += (" " * MEMORY_MAP_INDENT + "Memory map:") if show_memory_map?

      header += "\n"

      header
    end

    def memory_map
      return [] unless show_memory_map?

      memory_map_location = @memory_map_start

      Ruby6502.read(
        location: @memory_map_start,
        bytes: @memory_map_bytes,
      ).each_slice(MEMORY_MAP_WIDTH).map do |byte_array|
        memory_string = format("0x%04x:", memory_map_location)
        byte_array.each do |byte|
          memory_string << " " + format("%02x", byte)
        end

        memory_map_location += MEMORY_MAP_WIDTH
        memory_string
      end
    end

    def memory_map_columns
      @memory_map_columns ||= (" " * "0x0000: ".size) + "x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 xa xb xc xd xe xf"
    end

    def register_info
      "A: $#{format("%02x",
        Ruby6502.a_register)}  X: $#{format("%02x", Ruby6502.x_register)}  Y: $#{format("%02x", Ruby6502.y_register)}"
    end

    def stack_pointer_and_program_counter
      "SP: $#{format("%02x", Ruby6502.stack_pointer)}  PC: $#{format("%04x", Ruby6502.program_counter)}"
    end

    def status_header
      @status_header ||= (" " * "Status: ".length) + "NV-BDIZC"
    end

    def status_flags
      "Status: #{format("%08b", Ruby6502.status_flags)}"
    end

    def instruction_count
      "IC: #{Ruby6502.instruction_count}"
    end

    def interrupt_asserted_and_timing
      int = (interrupt_asserted? ? "INT" : "   ")
      freq = @delta_time > 0 ? @delta_instructions/@delta_time : nil

      "#{int}   #{format("%.2f", freq/1000000.0)} MHz"
    end

    def info_body
      [
        register_info,
        stack_pointer_and_program_counter,
        status_header,
        status_flags,
        instruction_count,
        interrupt_asserted_and_timing,
      ] + ([""] * 11)
    end

    def draw_info
      @window << info_header

      memory_map_lines = if show_memory_map?
        [memory_map_columns] + memory_map
      else
        []
      end

      info_body.each_with_index do |body_line, idx|
        @window << body_line

        if (memory_map_line = memory_map_lines[idx])
          @window << " " * (MEMORY_MAP_INDENT - body_line.size) + memory_map_line
        end

        @window << "\n"
      end
    end

    def execute_command
      case @debug_buffer
      when /\Arun/i
        @debug = false
        set_debug_state
      when /\Areset/i then Ruby6502.reset
      when /\Anmi\z/i then Ruby6502.non_maskable_interrupt
      when /\Airq\z/i then Ruby6502.interrupt_request
      when /mem (?:0x)?([A-Fa-f0-9]+)\s+([A-Fa-f0-9]+)?/i
        @memory_map_start = Regexp.last_match(1).to_i(16) & 0xffff
        @memory_map_bytes = [Regexp.last_match(2).to_i(16), 0x100].min
      when /hide mem/i
        @memory_map_start = nil
        @memory_map_bytes = nil
      when /\Akey (.{1})/
        keyboard.press(Regexp.last_match(1))
      when /\Astep (\d+)/
        Regexp.last_match(1).to_i.times { step_6502 }
      when /\Aq\z/i, /\Aquit/i
        exit(0)
      else
        @unknown_command = (@debug_buffer != "")
      end

      @debug_buffer = ""
    end

    def debug?
      @debug
    end

    def set_debug_state
      if debug?
        Curses.curs_set(1)
        @window.nodelay = false
      else
        Curses.curs_set(0)
        window.nodelay = true
      end
    end

    def profile
      videocard.profile
    end

    def lines
      LINE_PADDING + videocard.lines + INFO_LINES
    end

    def columns
      videocard.columns + (COLUMN_PADDING * 2)
    end

    def initialize_terminal
      @initial_terminal_y, @initial_terminal_x = IO.console.winsize
      print("\e]50;SetProfile=#{profile}\7")
      sleep(0.5)
      print("\e[8;#{lines};#{columns}t")
      sleep(0.5)

      Curses.init_screen
      Curses.start_color
      Curses.noecho

      @window = Curses::Window.new(
        lines - LINE_PADDING,
        columns - COLUMN_PADDING,
        LINE_PADDING,
        COLUMN_PADDING,
      )

      @window.keypad = true

      set_debug_state

      @window.refresh
    end

    def restore_terminal
      Curses.close_screen
      sleep(0.5)
      print("\e[8;#{@initial_terminal_y};#{@initial_terminal_x}t")
      sleep(0.5)
      print("\e]50;SetProfile=Default\7")
    end
  end
end
