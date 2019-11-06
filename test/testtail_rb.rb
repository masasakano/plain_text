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
    assert_empty e
    assert_equal 0, s.exitstatus, "error is raised: STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)
    assert_equal "", o

    stin = "1\n2\n3\n4\n5\n6\n7\n8\n9\nA\nB\n"
    o, e, s = Open3.capture3 EXE, stdin_data: stin
    assert_empty e, prerr(stin[2..-1], e)
    assert_equal 0, s.exitstatus
    assert_equal stin[2..-1], o, prerr(stin[2..-1], o)

    o, e, s = Open3.capture3 EXE+' -i', stdin_data: stin
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

  def prerr(*rest, long: true)
    '[期待] '+rest.map(&:inspect).join(" ⇔ "+(long ? "\n" : "")+'[実際] ')
  end
end # class TestUnitTailRb < MiniTest::Test

