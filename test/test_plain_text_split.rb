# -*- encoding: utf-8 -*-

# Author: M. Sakano (Wise Babel Ltd)

$stdout.sync=true
$stderr.sync=true

# print '$LOAD_PATH=';p $LOAD_PATH
arlibbase = %w(plain_text)

arlibrelbase = arlibbase.map{|i| "../lib/"+i}

arlibrelbase.each do |elibbase|
  require_relative elibbase
end	# arlibbase.each do |elibbase|

print "NOTE: Running: "; p File.basename(__FILE__)
print "NOTE: Library relative paths: "; p arlibrelbase
arlibbase4full = arlibbase.map{|i| i.sub(%r@^(../)+@, "")}
puts  "NOTE: Library full paths for #{arlibbase4full.inspect}: "
arlibbase4full.each do |elibbase|
  ar = $LOADED_FEATURES.grep(/(^|\/)#{Regexp.quote(File.basename(elibbase))}(\.rb)?$/).uniq
  print elibbase+": " if ar.empty?; p ar
end

#################################################
# Unit Test
#################################################

#if $0 == __FILE__
gem "minitest"
# require 'minitest/unit'
require 'minitest/autorun'
# MiniTest::Unit.autorun

class TestUnitPlainTextSplit < MiniTest::Test
  T = true
  F = false
  SCFNAME = File.basename(__FILE__)
  PTS = PlainText::Split

  class ChString < String
    # Test sub-class.
  end

  def setup
  end

  def teardown
  end

  def test_split_with_delimiter01
    s1 = "XabXXc"
    s2 = "XabXXcX"
    assert_equal [],  PTS.split_with_delimiter("", //)
    assert_equal [],  PTS.split_with_delimiter("", /g/)
    assert_equal [],  "".split_with_delimiter(/g/)
    assert_equal s1,  s1.split_with_delimiter(/X/).join
    assert_equal s2,  s2.split_with_delimiter(/X/).join
    assert_equal s1,  s1.split_with_delimiter(/_/).join
    assert_equal s2,  s2.split_with_delimiter(/_/).join

    a11 = ["", ?X, "ab", ?X, "", ?X, ?c]
    a12 = a11+[?X]
    assert_equal a11, PTS.split_with_delimiter(s1, /X/)
    assert_equal a11, s1.split_with_delimiter(/X/)
    assert_equal a11, s1.split_with_delimiter('X')
    assert_equal a12, s2.split_with_delimiter(/X/)
    assert_equal a12, s2.split_with_delimiter('X')

    a21 = ["", ?X, "ab", "XX", ?c]
    a22 = a21+[?X]
    assert_equal a21, s1.split_with_delimiter(/X+/)
    assert_equal a21, s1.split_with_delimiter(/X+(Y?)/)  # With grouping in the argument
    assert_equal a21, s1.split_with_delimiter(/(X+)((Y?)(Z?))/) # Even number of groupings
    assert_equal a22, s2.split_with_delimiter(/X+/)
    assert_equal a22, s2.split_with_delimiter(/X+(Y?)/)  # With grouping in the argument
    assert_equal a22, s2.split_with_delimiter(/(X+)((Y?)(Z?))/) # Even number of groupings
  end

  def test_split_with_delimiter02
    # As in the embedded comment
    s  = "XYabXXcXY"
    assert_equal ["", "ab", "c"],                   s.split(/X+Y?/)
    assert_equal ["", "ab", "c", ""],               s.split(/X+Y?/, -1)
    assert_equal ["", "Y", "ab", "", "c", "Y"],     s.split(/X+(Y?)/)
    assert_equal ["", "Y", "ab", "", "c", "Y", ""], s.split(/X+(Y?)/, -1)
    assert_equal ["", "XY", "Y", "ab", "XX", "", "c", "XY", "Y", ""], s.split(/(X+(Y?))/, -1)
    assert_equal ["", "XY", "ab", "XX", "c", "XY"], s.split_with_delimiter(/X+(Y?)/)
  end

  def test_count_regexp01
    s1 = "XabXXc"
    s2 = "XabXXcX"
    s3 = "XXabX+XcX"
    assert_equal 2, PTS.count_regexp(s1, /X+Y?/)
    assert_equal 2, s1.count_regexp(/X+Y?/)
    assert_equal 3, s1.count_regexp(/X+Y?/, like_linenum: true)
    assert_equal [2, false], s1.count_regexp(/X+Y?/, with_if_end: true)
    assert_equal [2, false], s1.count_regexp(/X+Y?/, with_if_end: true, like_linenum: false)
    assert_equal 3, s2.count_regexp(/X+Y?/)
    assert_equal 3, s2.count_regexp(/X+Y?/, like_linenum: true)
    assert_equal [3, true],  s2.count_regexp(/X+Y?/, with_if_end: true)
    assert_equal 0, s2.count_regexp('X+')
    assert_equal 1, s3.count_regexp('X+')
    assert_equal 2, s3.count_regexp('X+',   like_linenum: true)
    assert_equal [0, true],  ''.count_regexp(/X+Y?/, with_if_end: true)
  end

  def test_count_lines01
    s1 = "\nab\n\nc"
    s2 = "\nab\n\nc\n"
    s3 = "\r\n\nab\r\n+\r\n\r\n"
    assert_equal 4, PTS.count_lines(s1)
    assert_equal 4, s1.count_lines
    assert_equal 4, s2.count_lines
    assert_equal 0, ''.count_lines
    assert_equal 4, s3.count_lines(linebreak: "\r\n")
  end

end # class TestUnitPlainTextSplit < MiniTest::Test

