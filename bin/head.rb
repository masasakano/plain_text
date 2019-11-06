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
  ignore_case: false,
  inclusive: true,
  inverse: false,  # Option --reverse
  multi_line: false,
  # :chatter => 3,        # Default
  # debug: false,
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
  opt.on('-e REGEXP', '--regexp=REGEXP', sprintf("Regexp for the boundary, instead of a number.", (!OPTS[:num]).inspect)) {|v| OPTS[:num] = v}
  opt.on('-i', '--[no-]ignore-case', sprintf("Ignore case distinctions in Regexp (Def: %s)", (!OPTS[:ignore_case]).inspect), TrueClass) {|v| OPTS[:ignore_case] = v}
  opt.on('-m', '--[no-]multi-line', sprintf("Multi-line match (option m) in Regexp (Def: %s)", (!OPTS[:multi_line]).inspect), TrueClass) {|v| OPTS[:multi_line] = v}
  opt.on('-x', '--[no-]exclusive', sprintf("The line that matches is excluded? (Def: %s)", (!OPTS[:inclusive]).inspect), FalseClass) {|v| OPTS[:inclusive] = v}
  opt.on('-r', '--[no-]reverse', sprintf("Reverse the behaviour (print AFTER NUM-th line - inclusive|exclusive) (Def: %s)", (!OPTS[:inverse]).inspect), TrueClass) {|v| OPTS[:inverse] = v}  # WARNING-NOTE: the Hash keyword is "inverse" as opposed to "reverse"
  # opt.on(  '--version', "Display the version and exits.", TrueClass) {|v| OPTS[:version] = v}  # Consider opts.on_tail
  # opt.on(  '--[no-]debug', "Debug (Def: false)", TrueClass) {|v| OPTS[:debug] = v}
  # opt.separator ""        # Way to control a help message.
  opt.separator "Note:"
  opt.separator "  Option -m means '.' includes a newline. '\\s' includes it regardless."

  begin
    opt.parse!(ARGV)
  rescue OptionParser::MissingArgument => er
    # Missing argument like "-b" without a number.
    warn er
    exit 1
  end

  if OPTS[:num].respond_to? :to_str
    # Regexp specified with --regexp=REGEXP
    cond =  (0 | (OPTS[:ignore_case] ? Regexp::IGNORECASE : 0) | (OPTS[:multi_line] ? Regexp::MULTILINE : 0))
    OPTS[:num] = Regexp.new OPTS[:num], cond
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
# $DEBUG = true if opts[:debug]  # Better specify by running this script with ruby --debug

%i(num inverse debug).each do |ek|
  opts.delete ek if opts.has_key? ek
end

str = ARGF.read

method = (is_inverse ? :head_inverse : :head)
sout = PlainText.public_send(method, str, num_in, **opts)

# A linebreak guaranteed at the end, unless it is empty.
puts sout if !sout.empty?

exit

__END__

