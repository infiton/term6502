# term6502

## Installation

Go to `support/fonts` and add the `ModernDOS4378x8.ttf` font to your fontbook (i.e. install the font on mac os). You need to have iTerm2 installed and then:

```sh
ln -s $(pwd)/support/iterm/term6502-profiles.json ~/Library/Application\ Support/iTerm2/DynamicProfiles/

gem build term6502.gemspec
gem install term6502-0.1.0.gem

term6502 -h
```