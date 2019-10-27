#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'optparse'
require 'plain_text'

BANNER = <<"__EOF__"
USAGE: #{File.basename($0)} [options] [INFILE.txt] < STDIN
  Head command with (multi-byte) character-based manipulation and Regexp.
__EOF__

# Initialising the hash for the command-line options.
OPTS = {
  num: PlainText::DEF_HEADTAIL_N_LINES, 
  unit: :line,
  inclusive: true,
  inverse: false,  # unique option
  # :chatter => 3,        # Default
  debug: false,
}

# Function to handle the command-line arguments.
#
# ARGV will be modified, and the constant variable OPTS is set.
#
# @return [Hash]  Optional-argument hash.
#
def handle_argv
  opt = OptionParser.new(BANNER)
  opt.separator "Options:"        # Way to control a help message.
  opt.on('-n NUM', '--line=NUM', sprintf("Number of lines (Def: %d).", PlainText::DEF_HEADTAIL_N_LINES), Integer) { |v| OPTS[:num]=v }
  opt.on('-c NUM', '--byte=NUM', sprintf("Number of bytes, instead of lines."), Integer) { |v| OPTS[:unit] = :byte; OPTS[:num]=v }
  opt.on(  '--char=NUM',    sprintf("Number of characters, instead of lines."), Integer) { |v| OPTS[:unit] = :char; OPTS[:num]=v }
  opt.on('-e REGEXP', '--regexp=REGEXP', sprintf("Regexp for the boundary, instead of a number.", (!OPTS[:num]).inspect)) {|v| OPTS[:num] = Regexp.new v}
  opt.on('-x', '--[no-]exclusive', sprintf("The line that matches is excluded? (Def: %s)", (!OPTS[:inclusive]).inspect), FalseClass) {|v| OPTS[:inclusive] = v}
  opt.on('-i', '--[no-]inverse', sprintf("Inverse the result (print after NUM-th line) (Def: %s)", (!OPTS[:inverse]).inspect), TrueClass) {|v| OPTS[:inverse] = v}
  # opt.on(  '--version', "Display the version and exits.", TrueClass) {|v| OPTS[:version] = v}  # Consider opts.on_tail
  # opt.on(  '--[no-]debug', "Debug (Def: false)", TrueClass) {|v| OPTS[:debug] = v}
  # opt.separator ""        # Way to control a help message.
  # opt.separator "Note:"
  # opt.separator " Spaces are truncated in default."

  begin
    opt.parse!(ARGV)
  rescue OptionParser::MissingArgument => er
    # Missing argument like "-b" without a number.
    warn er
    exit 1
  end

  OPTS
end


################################################
# MAIN
################################################

$stdout.sync=true
$stderr.sync=true

class String
  include PlainText
end

# Handle the command-line options => OPTS
opts = handle_argv()
num_in = opts[:num]
is_inverse = opts[:inverse]

%i(num inverse debug).each do |ek|
  opts.delete ek if opts.has_key? ek
end

str = ARGF.read

# A linebreak guaranteed at the end.
if is_inverse
  puts PlainText.head_inverse(str, num_in, **opts)
else
  puts PlainText.head(str, num_in, **opts)
end

exit

__END__

