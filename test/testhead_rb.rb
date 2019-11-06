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

  def test_countchar01
    o, e, s = Open3.capture3 EXE
    assert_equal 0, s.exitstatus, "error is raised: STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)
    assert_equal "", o
    assert_empty e

    stin = "1\n2\n3\n4\n5\n6\n7\n8\n9\nA\nB\n"
    o, e, s = Open3.capture3 EXE, stdin_data: stin
    assert_equal 0, s.exitstatus
    assert_equal stin[0..19], o
    assert_empty e

    o, e, s = Open3.capture3 EXE+' -i', stdin_data: stin
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

    o, e, s = Open3.capture3 EXE+' -e "no_match" -i', stdin_data: stin
    assert_equal 0, s.exitstatus
    assert_equal '', o, prerr('', o)
    assert_empty e
  end

  def prerr(*rest, long: true)
    '[期待] '+rest.map(&:inspect).join(" ⇔ "+(long ? "\n" : "")+'[実際] ')
  end
end # class TestUnitHeadRb < MiniTest::Test

