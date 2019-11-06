# -*- encoding: utf-8 -*-

# Tests of an executable.
#
# @author M. Sakano (Wise Babel Ltd)

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

class TestUnitHeadRb < MiniTest::Test
  T = true
  F = false
  SCFNAME = File.basename(__FILE__)
  EXE = "%s/../bin/%s" % [File.dirname(__FILE__), File.basename(__FILE__).sub(/^test_?(.+)\.rb/, '\1').sub(/_rb$/, '.rb')]

  def setup
  end

  def teardown
  end

  def test_head01
    o, e, s = Open3.capture3 EXE
    assert_equal 0, s.exitstatus, "error is raised: STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)
    assert_equal "", o
    assert_empty e

    stin = "1\n2\n3\n4\n5\n6\n7\n8\n9\nA\nB\n"
    o, e, s = Open3.capture3 EXE, stdin_data: stin
    assert_equal 0, s.exitstatus
    assert_equal stin[0..19], o
    assert_empty e

    o, e, s = Open3.capture3 EXE+' -r', stdin_data: stin
    assert_equal 0, s.exitstatus
    assert_equal stin[20..-1], o, "Wrong! STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)
    assert_empty e

    o, e, s = Open3.capture3 EXE+' -n 10', stdin_data: stin
    assert_equal 0, s.exitstatus
    assert_equal stin[0..19], o
    assert_empty e

    o, e, s = Open3.capture3 EXE+' -b', stdin_data: stin
    assert_equal 1, s.exitstatus, "error is raised: STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)
    assert_match(/missing/i, e)

    o, e, s = Open3.capture3 EXE+' -e "[5-9]"', stdin_data: stin
    assert_equal 0, s.exitstatus
    assert_equal stin[0..9], o, "Wrong! STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)
    assert_empty e

    o, e, s = Open3.capture3 EXE+' -e "[5-9]" -x', stdin_data: stin
    assert_equal 0, s.exitstatus, "error is raised: STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)
    assert_equal stin[0..7], o, "Wrong! STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)
    assert_empty e

    o, e, s = Open3.capture3 EXE+' -e "no_match" -r', stdin_data: stin
    assert_equal 0, s.exitstatus
    assert_equal '', o, prerr('', o)
    assert_empty e
  end

  def test_head02
    stin = "A\nB\nC\nD\ne\nf\ng\nH\nI\nJ\nK\n"

    o, e, s = Open3.capture3 EXE+' -e "c"', stdin_data: stin
    assert_equal 0, s.exitstatus, comerr(o, e, s)
    assert_empty e, prerr('',e)
    assert_equal stin, o, prerr(s,o)

    o, e, s = Open3.capture3 EXE+' -e "c" -i', stdin_data: stin
    assert_equal 0, s.exitstatus, comerr(o, e, s)
    assert_empty e, prerr('',e)
    exp = "A\nB\nC\n"
    assert_equal exp, o, prerr(exp,o)

    o, e, s = Open3.capture3 EXE+' -e "c.*D" -i', stdin_data: stin
    assert_equal 0, s.exitstatus, comerr(o, e, s)
    assert_empty e, prerr('',e)
    assert_equal stin, o, prerr(exp,o)

    o, e, s = Open3.capture3 EXE+' -e "c.*D" -i -m', stdin_data: stin
    assert_equal 0, s.exitstatus, comerr(o, e, s)
    assert_empty e, prerr('',e)
    exp = "A\nB\nC\nD\n"
    assert_equal exp, o, prerr(exp,o)

  end

  def comerr(o, e, s)
    'コマンドエラー(status=%s): STDOUT=%s STDERR=%s'%[s.exitstatus, o.inspect, (e.empty? ? '""' : ":\n"+e)]
  end

  # Default error-printing routine, so they are compared easily.
  # This is especially useful when the expected/actual object contains
  # linefeed or space characters, as they are not very visible
  # hence comparable in the minitest default output.
  #
  # @param expected [Object] Expected object.
  # @param actual   [Object] Actual object your code has returned.
  # @param long: [Boolena] If true, linefeed is inserted (Better for String comparison).
  # @return [String] Error message when failed.
  def prerr(expected, actual, long: true)
    '[期待] '+[expected, actual].map(&:inspect).join(" ⇔ "+(long ? "\n" : "")+'[実際] ')
  end
end # class TestUnitHeadRb < MiniTest::Test

