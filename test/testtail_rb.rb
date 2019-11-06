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

class TestUnitTailRb < MiniTest::Test
  T = true
  F = false
  SCFNAME = File.basename(__FILE__)
  EXE = "%s/../bin/%s" % [File.dirname(__FILE__), File.basename(__FILE__).sub(/^test_?(.+)\.rb/, '\1').sub(/_rb$/, '.rb')]

  def setup
  end

  def teardown
  end

  def test_tail01
    o, e, s = Open3.capture3 EXE
    assert_equal 0, s.exitstatus, "error is raised: STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)
    assert_empty e
    assert_equal "", o

    stin = "1\n2\n3\n4\n5\n6\n7\n8\n9\nA\nB\n"
    o, e, s = Open3.capture3 EXE, stdin_data: stin
    assert_empty e, prerr(stin[2..-1], e)
    assert_equal 0, s.exitstatus
    assert_equal stin[2..-1], o, prerr(stin[2..-1], o)

    o, e, s = Open3.capture3 EXE+' -r', stdin_data: stin
    assert_empty e
    assert_equal 0, s.exitstatus
    assert_equal stin[0..1], o, "Wrong! STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)

    o, e, s = Open3.capture3 EXE+' -n 10', stdin_data: stin
    assert_empty e
    assert_equal 0, s.exitstatus
    assert_equal stin[2..-1], o

    o, e, s = Open3.capture3 EXE+' -b', stdin_data: stin
    assert_equal 1, s.exitstatus, "error is raised: STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)
    assert_match(/missing/i, e)

    o, e, s = Open3.capture3 EXE+' -e "[5-9]"', stdin_data: stin
    assert_empty e
    assert_equal 0, s.exitstatus
    assert_equal stin[-6..-1], o, "Wrong! STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)

    o, e, s = Open3.capture3 EXE+' -e "[5-9]" -x', stdin_data: stin
    assert_empty e
    assert_equal 0, s.exitstatus, "error is raised: STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)
    assert_equal stin[-4..-1], o, "Wrong! STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)

    o, e, s = Open3.capture3 EXE+' -e "no_match"', stdin_data: stin
    assert_empty e
    assert_equal 0, s.exitstatus
    assert_equal '', o, prerr('', o)

  end

  def test_tail02
    stin = "A\nB\nC\nD\ne\nf\ng\nH\nI\nJ\nK\n"

    o, e, s = Open3.capture3 EXE+' -e "i"', stdin_data: stin
    assert_equal 0, s.exitstatus, comerr(o, e, s)
    assert_empty e, prerr('',e)
    assert_equal "", o, prerr("",o)

    o, e, s = Open3.capture3 EXE+' -e "i" -i', stdin_data: stin
    assert_equal 0, s.exitstatus, comerr(o, e, s)
    assert_empty e, prerr('',e)
    exp = "I\nJ\nK\n"
    assert_equal exp, o, prerr(exp,o)

    o, e, s = Open3.capture3 EXE+' -e "i.*J" -i -m', stdin_data: stin
    assert_equal 0, s.exitstatus, comerr(o, e, s)
    assert_empty e, prerr('',e)
    exp = "I\nJ\nK\n"
    assert_equal exp, o, prerr(exp,o)

    o, e, s = Open3.capture3 EXE+' -e "i.*J" -i', stdin_data: stin
    assert_equal 0, s.exitstatus, comerr(o, e, s)
    assert_empty e, prerr('',e)
    assert_equal "", o, prerr("",o)

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
end # class TestUnitTailRb < MiniTest::Test

