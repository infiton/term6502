# frozen_string_literal: true

require File.expand_path("lib/term6502/version", __dir__)

Term6502::GEMSPEC = Gem::Specification.new do |s|
  s.name        = "term6502"
  s.version     = Term6502::VERSION
  s.summary     = "Terminal 6502 emulator."
  s.description = "A curses based terminal application to emulate a 6502 with customizable peripherals."
  s.authors     = ["Kyle Tate"]
  s.email       = "kbt.tate@gmail.com"
  s.files       = Dir.glob("{lib}/**/*") + Dir.glob("{bin}/**/*")

  s.required_ruby_version = ">= 2.4"
  s.add_runtime_dependency("ruby6502", [">= 0.1"])
  s.executables = ["term6502"]
  s.homepage    = "http://github.com/infiton/term6502"
  s.license     = "MIT"
end
