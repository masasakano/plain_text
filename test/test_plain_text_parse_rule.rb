# -*- encoding: utf-8 -*-

# Author: M. Sakano (Wise Babel Ltd)

require 'plain_text'
require 'plain_text/parse_rule'

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

class TestUnitPlainTextParseRule < MiniTest::Test
  T = true
  F = false
  SCFNAME = File.basename(__FILE__)
  PR = PlainText::ParseRule
  PRLb = PR::RuleConsecutiveLbs

  def setup
  end

  def teardown
  end

  def test_new01
    re1 = /(\n{2,})/
    pr1 = PR.new re1, name: :std
    assert_equal [re1],   pr1.rules
    assert_equal ['std'], pr1.names

    re2 = /\s*=\s*/i
    pr1.push re2, name: 'equ'
    assert_equal [re1, /(\s*=\s*)/i], pr1.rules  # Grouping in Regexp added by ParseRule#add_grouping (Private method)
    assert_equal ['std', 'equ'],      pr1.names
  end

  def test_clone
    re2 = /(\s*=\s*)/
    assert_output(nil, /frozen|freeze/i){ PRLb.clone }   # STDOUT is whatever (to suppress it)

    pr1 = PR.new(/abc/)
    assert_output("", ""){ pr1.clone }
    pr2 = pr1.clone
    pr2.push re2, name: 'new'
    assert_equal 1, pr1.size, "pr1.rules-id=#{pr1.rules.object_id}, pr2.rules-id=#{pr2.rules.object_id}"
    assert_equal 2, pr2.size
  end

  def test_dup
    pr1 = PRLb.dup
    re2 = /(\s*=\s*)/
    pr1.push re2, name: 'new'
    assert_equal 1, PRLb.size
    assert_equal 2, pr1.size
  end

  def test_apply01
    str = "\n\n\nFirst = para. \n\n"
    ar = PRLb.apply str
    assert_equal ['ConsecutiveLbs'], PRLb.names
    assert_equal Array, ar.class
    assert_equal 4,     ar.size, "Wrong returned array = #{ar.inspect}"
    assert_equal ["", "\n\n\n", 'First = para. ', "\n\n"], ar
  end 

  def test_apply02
    str = "\n\n\nFirst = para. \n\n"
    re1 = /(\n{2,})/
    re2 = /(\s*=\s*)/

    pr2 = PR.new re1, name: :std
    ar1 = pr2.apply str
    assert_equal 4,     ar1.size, "Wrong returned array = #{ar1.inspect}"
    assert_equal ["", "\n\n\n", 'First = para. ', "\n\n"], ar1

    # Two Regexp applied freshly.
    pr2.push re2
    assert_equal [re1, re2],   pr2.rules
    assert_equal ['std', nil], pr2.names
    pr2.set_name_at(:myname, 1)              # Test  of ParseRule#set_name_at
    assert_equal ['std',  'myname'], pr2.names
    assert_equal re2, pr2.rule_at('myname')  # Tests of ParseRule#rule_at
    assert_equal re2, pr2.rule_at(:myname)
    assert_equal re2, pr2.rule_at(1)
    assert_nil        pr2.rule_at('naiyo')
    ar2 = pr2.apply str
    assert_equal 6,     ar2.size, "Wrong returned array = #{ar2.inspect}"
    assert_equal ["", "\n\n\n", "First", " = ", "para. ", "\n\n"], ar2, "Wrong returned array = #{ar2.inspect}"

    # Third Proc, applied independently for an Array, called by name.
    pr2.push(name: 'paranize'){ |arin| (defined?(arin.map) ? arin : [arin]).map{|i| ("First"==i) ? PlainText::Part::Paragraph.new(i) : i} } 
    ar3 = pr2.apply ar2, index: :paranize  # index can be specified either String or Symbol (or index)
    assert_equal ["", "\n\n\n", "First", " = ", "para. ", "\n\n"], ar3, "Wrong returned array = #{ar3.inspect}"
    assert_equal PlainText::Part::Paragraph, ar3[2].class

    # Fourth Proc, applied independently for an Array, called by index.
    mk_bound = Proc.new{ |arin| (defined?(arin.map) ? arin : [arin]).map{|i| (/\n+/m =~ i) ? PlainText::Part::Boundary.new(i) : i} } 
    pr2.push(mk_bound)
    ar4 = pr2.apply ar3, index: 3
    assert_equal ["", "\n\n\n", "First", " = ", "para. ", "\n\n"], ar4, "Wrong returned array = #{ar4.inspect}"
    assert  ar4[0].empty?
    assert_equal PlainText::Part::Boundary,  ar4[1].class
    assert_equal PlainText::Part::Paragraph, ar4[2].class
    assert_equal String,                     ar4[3].class
    assert_equal String,                     ar4[4].class
    assert_equal PlainText::Part::Boundary,  ar4[5].class

    # Tests of pop
    assert_equal 4, pr2.rules.size
    assert_equal 4, pr2.names.size
    pr2.pop
    assert_equal 3, pr2.rules.size
    assert_equal 3, pr2.names.size

    assert_raises(RuntimeError){ pr2.set_name_at(       'myname', 2) }  # name already used
    assert_raises(RuntimeError){ pr2.send(:set_name_at, :myname,  2) }  # name already used
  end

  def test_apply03
    str = "\n\n\nFirst = para. \n\n"
    re1 = /(\n{2,})/
    re2 = /(\s)/

    pr2 = PR.new [re1, re2]
    ar2 = pr2.apply str
    assert_equal 2,     pr2.size
    assert_equal 8,     ar2.size, "Wrong returned array = #{ar2.inspect}"
    assert_equal ["", "\n\n\n", "First", " ", "=", " ", "para.",  " \n\n"], ar2, "Wrong returned array = #{ar2.inspect}"
  end

    #assert_operator pt2, '!=', a2
    #assert_match(/^\s*ADD CONSTRAINT/ , s1.instance_eval{ @strall })
end	# class TestUnitPlainTextParseRule < MiniTest::Test

#end	# if $0 == __FILE__

