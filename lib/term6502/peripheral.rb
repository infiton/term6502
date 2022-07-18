# frozen_string_literal: true

module Term6502
  module Peripheral
    def type
      self.class.name.split("::").last.downcase
    end

    def needs_timing?
      false
    end

    def asserting?
      @asserting
    end

    def tick(ticks); end
  end
end
