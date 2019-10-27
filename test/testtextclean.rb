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

class TestUnitTextclean < MiniTest::Test
  T = true
  F = false
  SCFNAME = File.basename(__FILE__)
  EXE = "%s/../bin/%s" % [File.dirname(__FILE__), File.basename(__FILE__).sub(/^test_?(.+)\.rb/, '\1')]

  def setup
  end

  def teardown
  end

  def test_textclean01
    o, e, s = Open3.capture3 EXE
    assert_equal 0, s.exitstatus, "error is raised: STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)
    assert_equal "", o.chomp
    assert_empty e

    stin = "foo\n\n\nbar\n"
    s2   = "foo\n\nbar\n"
    #o, e, s = Open3.capture3 EXE, stdin_data: stin
    #assert_equal 0, s.exitstatus
    #assert_equal s2, o
    #assert_empty e

    o, e, s = Open3.capture3 EXE+' --lastsps-style=delete', stdin_data: stin
    assert_equal 0, s.exitstatus
    assert_equal s2.chop.chomp, o, "Wrong! STDOUT="+o.inspect+" STDERR="+(e.empty? ? '""' : ":\n"+e)
    assert_empty e
  end
end # class TestUnitTextclean < MiniTest::Test

