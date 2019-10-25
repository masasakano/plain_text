# -*- encoding: utf-8 -*-

# Author: M. Sakano (Wise Babel Ltd)

require 'plain_text'

$stdout.sync=true
$stderr.sync=true
# print '$LOAD_PATH=';p $LOAD_PATH

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

end # class TestUnitPlainTextSplit < MiniTest::Test

