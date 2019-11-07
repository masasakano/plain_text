# -*- encoding: utf-8 -*-

# Tests of an executable.
#
# @author: M. Sakano (Wise Babel Ltd)

require 'open3'

$stdout.sync=true
$stderr.sync=true
# print '$LOAD_PATH=';p $LOAD_PATH

#################################################
# Unit Test
#################################################

gem "minitest"
# require 'minitest/unit'
require 'minitest/autorun'

class TestUnitYard2mdRb < MiniTest::Test
  T = true
  F = false
  SCFNAME = File.basename(__FILE__)
  EXE = "%s/../bin/%s" % [File.dirname(__FILE__), File.basename(__FILE__).sub(/^test_?(.+)\.rb/, '\1').sub(/_rb$/, '.rb')]

  def setup
  end

  def teardown
  end

  def test_basics01

    o, e, s = Open3.capture3 EXE
    assert_equal 0, s.exitstatus, "error is raised: STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)
    assert_equal "\n", o
    assert_empty e

    stin = " +abc def+ \n\n efg\n"
    o, e, s = Open3.capture3 EXE, stdin_data: stin
    assert_equal 0, s.exitstatus
    exp = " `abc def` \n\n efg\n"
    assert_equal exp, o, "期待:#{exp.inspect} ⇔ \n実際:#{o.inspect}"
    assert_empty e

    stin = " +abc\ndef+ \n\n efg\n"
    o, e, s = Open3.capture3 EXE, stdin_data: stin
    assert_equal 0, s.exitstatus
    exp = " `abc def` \n\n efg\n"
    assert_equal exp, o, "期待:#{exp.inspect} ⇔ \n実際:#{o.inspect}"
    assert_empty e

    stin = " [abc\ndef](http://xy\n  .h\n  tml) \n\n efg\n"
    o, e, s = Open3.capture3 EXE, stdin_data: stin
    assert_equal 0, s.exitstatus
    exp = " [abc def](http://xy.html) \n\n efg\n"
    assert_equal exp, o, "期待:#{exp.inspect} ⇔ \n実際:#{o.inspect}"
    assert_empty e

    stin = "    +abc def+ " + "\n\n\n efg\n"
    srub = "```ruby\n"
    exp = srub+"+abc def+ \n```\n\n\n efg\n"
    o, e, s = Open3.capture3 EXE, stdin_data: stin
    assert_equal 0, s.exitstatus
    assert_equal exp, o, "期待:#{exp.inspect} ⇔ \n実際:#{o.inspect}"
    assert_empty e

  end
end

