# -*- encoding: utf-8 -*-

# Author: M. Sakano (Wise Babel Ltd)

require 'plain_text/util'

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

class TestUnitPlainTextUtil < MiniTest::Test
  T = true
  F = false
  SCFNAME = File.basename(__FILE__)
  include PlainText::Util

  def setup
  end

  def teardown
  end

  def test_arind2ranges
    assert_equal [(1..3), (6..7), (9..9)], arind2ranges([1,2,3,6,7,9])
  end
end
