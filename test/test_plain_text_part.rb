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
arlibbase4full = arlibbase.map{|i| i.sub(%r@^(../)+@, "")}+%w(part part/paragraph part/boundary plain_text/util builtin_type part/string_type)
puts  "NOTE: Library full paths for #{arlibbase4full.inspect}: "
arlibbase4full.each do |elibbase|
  #ar = $LOADED_FEATURES.grep(/(^|\/)#{Regexp.quote(File.basename(elibbase))}(\.rb)?$/).uniq
  ar = $LOADED_FEATURES.grep(/(^|\/)#{Regexp.quote(elibbase)}(\.rb)?$/).uniq
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

# NOTE: In Ruby 3, a subclass of Array is not respected in the methods of Array:
#  @see https://rubyreferences.github.io/rubychanges/3.0.html#array-always-returning-array
# NOTE: In Ruby 3, "".class.name is frozen?==true
require 'rubygems' if !defined? Gem  # for Ruby 1
IS_VER_2 = (Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3'))

class PlainText::Part::Boundary::MyA < PlainText::Part::Boundary
end

class TestUnitPlainTextPart < MiniTest::Test
  T = true
  F = false
  SCFNAME = File.basename(__FILE__)
  Pt = PlainText::Part

  def setup
  end

  def teardown
  end

  def test_new01
    a1  = ["a", "\n\n\n", "b", "\n\n\n", "c", "\n\n"]
    ap1 = ["a",           "b",           "c"]
    ab1 = [     "\n\n\n",      "\n\n\n",      "\n\n"]
    a2  = ["a", "\n\n\n", "b", "\n\n\n", "c"]
    ap2 = ap1
    ab2 = [     "\n\n\n",      "\n\n\n",      ""]

    pt1 = Pt.new(a1)
    # p a1
    # p a1.class
    # p a1.object_id
    # p pt1
    # p pt1.class
    # p pt1.object_id
    # p pt1.to_a
    # p pt1.to_a.object_id
    # p pt1.to_a.class
    assert_equal a1[0], pt1[0]
    assert_equal a1[1], pt1[1]
    assert_equal ap1,   pt1.paras
    assert_equal ab1,   pt1.boundaries
    assert_equal a1,    pt1.to_a
    assert_operator a1,  '!=', pt1
    assert_operator pt1, '!=', a1

    pt2 = Pt.new(a2)
    assert_equal a2[0], pt2[0]
    assert_equal a2[2], pt2[2]
    assert_equal ap2,   pt2.paras
    assert_equal ab2,   pt2.boundaries
    assert_equal a2+[""], pt2.to_a, "former=#{a2+['']} <=> #{pt2.to_a}"  # An empty String is appended.
    assert_operator a2,  '!=', pt2
    assert_operator pt2, '!=', a2
  end

  def test_new02
    a1  = ["a", "\n\n\n", "b", "\n\n\n", "c", "\n\n"]
    ap1 = ["a",           "b",           "c"]
    ab1 = [     "\n\n\n",      "\n\n\n",      "\n\n"]
    a2  = ["a", "\n\n\n", "b", "\n\n\n", "c"]
    ap2 = ap1
    ab2 = [     "\n\n\n",      "\n\n\n",      ""]

    pt11 = Pt.new(a1)
    pt12 = Pt.new(ap1, ab1)
    assert_equal pt11, pt12, "pt11.inspect=#{pt11.inspect}"
    pt21 = Pt.new(a2)
    pt22 = Pt.new(ap2, ab2)
    assert_equal pt21, pt22
  end

  def test_new03
    assert_raises(ArgumentError){ Pt.new(?a) }
    assert_raises(ArgumentError){ Pt.new(3) }
    assert_raises(TypeError){ Pt.new([Pt::Boundary.new(""),  Pt::Boundary.new("\n") ]) }
    assert_raises(TypeError){ Pt.new([Pt::Paragraph.new(""), Pt::Paragraph.new("a")]) }
  end

  def test_size2extract01
    a1  = ["a", "\n\n\n", "b", "\n\n\n", "c", "\n\n"]
    pt1 = Pt.new(a1)
    assert_equal 1, pt1.send(:size2extract, 0,   1,  ignore_error: false, skip_renormalize: false)
    assert_equal 0, pt1.send(:size2extract, 9,   1,  ignore_error: false, skip_renormalize: false)
    assert_equal 1, pt1.send(:size2extract, -1,  1,  ignore_error: false, skip_renormalize: false)
    assert_equal 1, pt1.send(:size2extract, -1,  5,  ignore_error: false, skip_renormalize: false)
    assert_equal 1, pt1.send(:size2extract, 5,   9,  ignore_error: false, skip_renormalize: false)
    assert_equal 1, pt1.send(:size2extract, -1,  9,  ignore_error: false, skip_renormalize: false)
    assert_equal 0, pt1.send(:size2extract, 8,   9,  ignore_error: false, skip_renormalize: false)
    assert_equal 2, pt1.send(:size2extract, (0..1),  ignore_error: false, skip_renormalize: false)
    assert_equal 2, pt1.send(:size2extract, (0...2), ignore_error: false, skip_renormalize: false)
    assert_equal 6, pt1.send(:size2extract, (0..-1), ignore_error: false, skip_renormalize: false)
    assert_equal 0, pt1.send(:size2extract, (0..-1), ignore_error: false, skip_renormalize: true)
    assert_equal 4, pt1.send(:size2extract, (0...-2), ignore_error: false, skip_renormalize: false)
    assert_equal 0, pt1.send(:size2extract, (2..1),  ignore_error: false, skip_renormalize: false)
    assert_equal 1, pt1.send(:size2extract, (5..9),  ignore_error: false, skip_renormalize: false)
    assert_equal 1, pt1.send(:size2extract, (5...9), ignore_error: false, skip_renormalize: false)
    assert_equal 0, pt1.send(:size2extract, (8..9),  ignore_error: false, skip_renormalize: false)
    assert_nil                 pt1.send(:size2extract, (-9..-1), ignore_error: true,  skip_renormalize: false)
    assert_raises(IndexError){ pt1.send(:size2extract, (-9..-1), ignore_error: false, skip_renormalize: false) }
    assert_raises(IndexError){ pt1.send(:size2extract, (1..-9),  ignore_error: false, skip_renormalize: false) }
    assert_raises(IndexError){ pt1.send(:size2extract, (-9..-9), ignore_error: false, skip_renormalize: false) }
  end


  def test_equal01
    a1  = ["a", "\n\n\n", "b", "\n\n\n", "c", "\n\n"]
    pt1 = Pt.new(a1)
    a2  = ["a", "\n\n\n", "b", "\n\n\n", "c"]
    pt2 = Pt.new(a2)

    assert_operator pt1, '==', Pt.new(a1)
    assert_operator pt1, '==', Pt.new(a1.dup)
    assert_operator pt1, '==', Pt.new(pt1.deepcopy.to_a)
    assert_operator a1,  '==', pt1.to_a
    assert_operator a1,  '!=', pt1
    assert_operator pt1, '!=', a1
    assert_operator pt1, '!=', pt2
    assert_operator pt2, '!=', pt1
    assert_operator pt1, '!=', ?a
    assert_operator ?a,  '!=', pt1
  end

  def test_equal02_para_boundary
    pa1 = Pt::Paragraph.new("abc")
    bo1 = Pt::Boundary.new("\n\n")
    assert_equal pa1, "abc"
    assert_equal "abc", pa1
    assert_equal pa1, Pt::Paragraph.new("abc")
    assert_equal bo1, "\n\n"
    assert_equal "\n\n", bo1
    assert_equal bo1, Pt::Boundary.new("\n\n")

    assert_respond_to pa1, :+
    assert_respond_to bo1, :gsub!
  end

  def test_nomethoderror01
    a1  = ["a", "\n\n\n", "b", "\n\n\n", "c", "\n\n"]
    pt1 = Pt.new(a1)
    assert_raises(NoMethodError){ pt1 << 'abc' }
    assert_raises(NoMethodError){ pt1.delete_at(2) }
  end

  def test_plus01
    a1  = ["a", "\n\n\n", "b", "\n\n\n", "c", "\n\n"]
    pt1 = Pt.new(a1)
    a3  = ["a", "\n\n\n", "b", "\n\n\n", "c", "\n\n", "d", ""]
    pt3 = pt1 + ["d"]  # PlainText::Part + Array => PlainText::Part

    assert_raises(TypeError){ pt1 + "s" }
    assert_equal a1+["d", ""], pt3.to_a
    assert_equal pt1.class,    pt3.class
    assert_equal Pt.new(a3),   pt3    # Boundary("") is appended.
    assert_equal Pt::Boundary, pt3.to_a[-1].class
    assert_equal pt3, pt1 + ["d", ""]

    assert_equal a3.class, ([]+pt3).class  # The latter, too, is an Array (NOT PlainText::Part)
    assert_equal a3,        []+pt3

    assert_equal pt3.class, (pt1 + Pt.new(["d", ""])).class  # PtP + PtP => PtP
    assert_equal pt3,        pt1 + Pt.new(["d", ""])
  end

  # Tests of [prm], [prm1, prm2], [prm1..prm2] and "equal" operator
  # NOTE: In Ruby 3, a subclass of Array is not respected in the methods of Array:
  #  @see https://rubyreferences.github.io/rubychanges/3.0.html#array-always-returning-array
  # NOTE: In Ruby 3, "".class.name is frozen?==true
  def test_bracket01
    a1  = ["a", "\n\n\n", "b", "\n\n\n", "c", "\n\n"]
    pt1 = Pt.new(a1)

    assert_equal pt1.to_a[0],   pt1[0]
    assert_equal Pt::Paragraph, pt1[0].class
    assert_equal a1[0],         pt1[0]
    assert_equal Pt::Paragraph.new(a1[0]), pt1[0]

    # negative or too-big out-of-bound begin
    assert_nil   pt1[-99]
    assert_nil   pt1[98]

    assert_equal pt1.class, pt1[0, 6].class
    assert_equal a1,        pt1[0, 6].to_a
    assert_equal a1[0, 6],  pt1[0, 6].to_a
    # oper = (IS_VER_2 ? :!= : :==)  # Because PlainText::Part#== is redefined and pt1 is Part in Ruby 2, the following is unequal, whereas pt1 is Array in Ruby 3!
    oper = :!=  # In Ver.0.8, it is redefined as unequal.
    assert_operator pt1[0, 6], oper, a1
    assert_operator a1,        oper, pt1[0, 6]

    assert_equal a1[0, 2],  pt1[0, 2].to_a
    assert_equal a1,        pt1[0, 98].to_a
    assert_equal a1[0, 99], pt1[0, 98].to_a

    assert_equal pt1.class, pt1[0..1].class
    assert_equal a1[0..1],  pt1[0..1].to_a
    assert_equal a1[0, 2],  pt1[0..1].to_a
    assert_equal a1[0..5],  pt1[0..5].to_a
    assert_equal a1,        pt1[0..5].to_a
    assert_equal a1[0..99], pt1[0..99].to_a
    assert_equal a1,        pt1[0..99].to_a
    assert_equal a1,        pt1[0..-1].to_a
    assert_equal a1[-6..-1],pt1[-6..-1].to_a
    assert_equal a1,        pt1[-6..-1].to_a
    assert_equal a1[-6..3], pt1[-6..3].to_a
    assert_equal a1[-6...4],pt1[-6...4].to_a

    assert_equal pt1[0..-1], pt1[0..99]
    assert_equal pt1[0, 6],  pt1[0..-1]
    assert_equal pt1,        pt1[0..99]

    pt2 = pt1[0, 4]
    assert_equal pt1.class,            pt2.class
    assert_equal pt1.paras[0, 2],      pt2.paras
    assert_equal pt1.boundaries[0, 2], pt2.boundaries

    # negative or too-big out-of-bound begin
    assert_nil   a1[-99..2]
    assert_nil   pt1[-99..2]
    assert_nil   pt1[-99..-1]
    assert_nil   pt1[98..99]

    # other out-of-bounds: Empty
    assert_equal a1[-2..2],   pt1[-2..2].to_a
    assert_equal a1[-2...3],  pt1[-2...3].to_a


    # Exception (Error)
    assert_raises(TypeError){ pt1['abc'] }
    assert_raises(TypeError){ a1[(?a)..(?c)] }
    assert_raises(TypeError){ pt1[(?a)..(?c)] }
    assert_raises(ArgumentError){ pt1[0, 1] }
    assert_raises(ArgumentError){ pt1[1, 2] }

    # Special cases, where the first index (or begin) is equal to size (as described in the reference) 
    # @see https://docs.ruby-lang.org/ja/latest/class/Array.html#I_--5B--5D
    assert_nil   pt1[pt1.size]
    assert_nil   pt1[pt1.size, -2]
    assert_raises(TypeError){ pt1[pt1.size, ?a] }
    assert_equal Pt.new([]), pt1[pt1.size, 2]
    assert_equal Pt.new([]), pt1[pt1.size, 98]
    assert_equal Pt.new([]), pt1[pt1.size..99]
    assert_equal Pt.new([]), pt1[pt1.size..1]
  end

  # Tests of slice! to delete
  def test_slice01
    a1  = ["a", "\n\n\n", "b", "\n\n\n", "c", "\n\n"]
    a11 = ["a", "\n\n\n", "b", "\n\n\n", "c", "\n\n"]  # a1.clone
    pt1 = Pt.new(a1.clone)
    pt2 = Pt.new(a11.clone)

    assert_equal pt1.to_a[0],   pt1[0]
    # negative or too-big out-of-bound begin
    assert_nil   a1.slice!( -98, 2)
    assert_nil   pt1.slice!(-98, 2)
    assert_nil   a1.slice!( 98, 2)
    assert_nil   pt1.slice!(98, 2)
    assert_equal a11,   a1
    assert_equal pt2,   pt1

    assert_equal a11[4, 2],  a1.slice!(4, 2)
    ptp =                   pt1.slice!(4, 2)
    assert_equal    pt1.class, ptp.class
    assert_equal    a11[4, 2], ptp.to_a
    assert_operator a11[4, 2], :!=, ptp   # PlainText::Part != Array
    assert_equal a11[0..3],  a1
    assert_equal a11[0..3], pt1.to_a
    assert_equal pt2[0..3], pt1

    # Negative size (Index, Size)
    a1  = a11.clone
    pt1 = Pt.new(a11.clone)
    assert_nil  a1.slice!(4, -1)
    ptp =      pt1.slice!(4, -1)
    assert_nil  ptp
    assert_equal a11,  a1
    assert_equal a11, pt1.to_a

    # Range exceeding (Index, Size)
    a1  = a11.clone
    pt1 = Pt.new(a11.clone)
    assert_equal a11[4, 6],  a1.slice!(4, 6)
    ptp =                   pt1.slice!(4, 6)
    assert_equal    pt1.class, ptp.class  # PlainText::Part
    assert_equal    a11[4, 2], ptp.to_a
    assert_operator a11[4, 2], :!=, ptp   # PlainText::Part != Array
    assert_equal a11[0..3],  a1

    # Range exceeding (Range)
    a1  = a11.clone
    pt1 = Pt.new(a11.clone)
    assert_equal a11[4..9],  a1.slice!(4..9)
    ptp =                   pt1.slice!(4..9)
    assert_equal    pt1.class, ptp.class  # PlainText::Part
    assert_equal    a11[4..-1],ptp.to_a
    assert_equal    a11[4..9], ptp.to_a
    assert_operator a11[4..9], :!=, ptp   # PlainText::Part != Array
    assert_equal a11[0..3],  a1
    assert_equal a11[0..3], pt1.to_a

    # Null Range (Range)
    a1  = a11.clone
    pt1 = Pt.new(a11.clone)
    assert_equal [],  a1.slice!(4..0)
    ptp =            pt1.slice!(4..0)
    # assert_equal    pt1.class, ptp.class  # PlainText::Part  -- No! In Ruby's specification (2.5), ptp is Array, not its subClass.
    assert_equal    [], ptp.to_a
    # assert_operator [], :!=, ptp   # PlainText::Part != Array  -- The same
    assert_equal a11,  a1
    assert_equal a11, pt1.to_a

    # Negative index (Index, size)
    a1  = a11.clone
    pt1 = Pt.new(a11.clone)
    assert_equal a11[-6, 2],  a1.slice!(-6, 2)
    ptp =                    pt1.slice!(-6, 2)
    assert_equal    pt1.class, ptp.class  # PlainText::Part
    assert_equal    a11[0..1], ptp.to_a
    assert_operator a11[0..1], :!=, ptp   # PlainText::Part != Array
    assert_equal a11[2..-1],  a1
    assert_equal a11[2..-1], pt1.to_a

    # Negative index (Range)
    a1  = a11.clone
    pt1 = Pt.new(a11.clone)
    assert_equal a11[-6..-5],  a1.slice!(-6..-5)
    ptp =                     pt1.slice!(-6..-5)
    assert_equal    pt1.class, ptp.class  # PlainText::Part
    assert_equal    a11[0..1], ptp.to_a
    assert_operator a11[0..1], :!=, ptp   # PlainText::Part != Array
    assert_equal a11[2..-1],  a1
    assert_equal a11[2..-1], pt1.to_a

    # Exception (Error)
    a1  = a11.clone
    pt1 = Pt.new(a11.clone)
    assert_raises(TypeError){ pt1['abc'] }
    assert_raises(TypeError){ a1[ (?a)..(?c)] }
    assert_raises(TypeError){ pt1[(?a)..(?c)] }
    assert_raises(ArgumentError){ pt1.slice!(0) }     # Single element forbidden.
    assert_raises(ArgumentError){ pt1.slice!(0, 3) }  # Odd-number elements forbidden.
    assert_raises(ArgumentError){ pt1.slice!(-1, 2) } # Odd-number elements forbidden.
    assert_raises(ArgumentError){ pt1.slice!(1, 2) }  # Odd starting index.
    assert_raises(ArgumentError){ pt1.slice!(1..2) }  # Odd starting index.
  end

  # merge paragraphs
  def test_merge_para
    s1 = "a\n\nb\n\nc\n\nd\n\ne\n\n"
    #     0 1  2 3  4 5  6 7  8 9
    pt1 = Pt.parse s1
    assert_equal 10, pt1.size
    assert_equal  5, pt1.paras.size
    assert_equal "b\n\n",      pt1[2..3].join

    pt2 = pt1.dup
    assert_equal 10, pt2.size, "Sanity check should pass: #{pt2.inspect}"
    pt2.merge_para!(2,3,4)
    assert_equal s1, pt2.join
    assert_equal  8, pt2.size
    assert_equal "b\n\nc\n\n", pt2[2..3].join

    pt2 = pt1.dup
    assert_equal 10, pt2.size, "Sanity check should pass: #{pt2.inspect}"
    pt2.merge_para!(2,3,4, 5)
    assert_equal s1, pt2.join
    assert_equal  8, pt2.size, "Size should be 8: pt2="+pt2.inspect
    assert_equal "b\n\nc\n\n", pt2[2..3].join

    pt2 = pt1.dup
    assert_equal 10, pt2.size, "Sanity check should pass: #{pt2.inspect}"
    pt2.merge_para!(2..4)
    assert_equal s1, pt2.join
    assert_equal  8, pt2.size
    assert_equal "b\n\nc\n\n", pt2[2..3].join

    pt2 = pt1.dup
    assert_equal 10, pt2.size, "Sanity check should pass: #{pt2.inspect}"
    pt2.merge_para!(2..5)
    assert_equal s1, pt2.join
    assert_equal  8, pt2.size
    assert_equal "b\n\nc\n\n", pt2[2..3].join

    pt2 = pt1.dup
    assert_equal 10, pt2.size, "Sanity check should pass: #{pt2.inspect}"
    pt2.merge_para!(2...6)
    assert_equal s1, pt2.join
    assert_equal  8, pt2.size
    assert_equal "b\n\nc\n\n", pt2[2..3].join

    pt2 = pt1.dup
    assert_equal 10, pt2.size, "Sanity check should pass: #{pt2.inspect}"
    pt2.merge_para!(2...-4)
    assert_equal s1, pt2.join
    assert_equal  8, pt2.size
    assert_equal "b\n\nc\n\n", pt2[2..3].join

    pt2 = pt1.dup
    assert_equal 10, pt2.size, "Sanity check should pass: #{pt2.inspect}"
    pt2.merge_para!(1..2, use_para_index: true)
    assert_equal s1, pt2.join
    assert_equal  8, pt2.size
    assert_equal "b\n\nc\n\n", pt2[2..3].join

    pt2 = pt1.dup
    assert_equal 10, pt2.size, "Sanity check should pass: #{pt2.inspect}"
    pt2.merge_para!(8..12)
    assert_equal s1, pt2.join
    assert_equal 10, pt2.size
    assert_equal pt1, pt2
  end

  def test_merge_para_if
    s1 = "a\n\nb\n\nc\n\nd\n\ne\n\n"
    #     0 1  2 3  4 5  6 7  8 9
    pt1 = Pt.parse s1

    pt2 = pt1.dup
    assert pt2.merge_para_if{|ary,bi,bf|
      ary[0] == ?b && ary[2] == ?c
    }
    assert_equal s1, pt2.join
    assert_equal  8, pt2.size
    assert_equal "b\n\nc\n\n", pt2[2..3].join

    # Multiple
    pt2 = pt1.dup
    assert pt2.merge_para_if{|ary,bi,bf|
      (ary[0] == ?a && ary[2] == ?b) || (ary[0] == ?d && ary[2] == ?e)
    }
    assert_equal s1, pt2.join
    assert_equal  6, pt2.size
    assert_equal ["a\n\nb", "\n\n", "c", "\n\n", "d\n\ne", "\n\n"], pt2.to_a
  end

  # Tests of Part.parse
  def test_parse01
    s1 = "a\n\n\nb\n\n\nc\n\n"
    pt1 = Pt.parse s1
    assert_equal 6, pt1.size
    assert_equal 3, pt1.paras.size
    assert_equal %w(a b c), pt1.paras
    assert_equal Pt::Paragraph, pt1[0].class
    assert_equal Pt::Boundary,  pt1[1].class
    assert_equal s1,  pt1.join
  end

  def test_subclass_name
    assert_equal "Boundary::MyA", Pt::Boundary::MyA.new("\n===\n").subclass_name
  end

  def test_dup
    pa1 = Pt::Paragraph.new("b")
    bo1 = Pt::Boundary::MyA.new("\n===\n")
    para1 = [Pt::Paragraph.new("a"), pa1, Pt::Paragraph.new("c")]
    boun1 = [Pt::Boundary.new("\n"), bo1, Pt::Boundary.new("\n")]
    pt1 = Pt.new(para1, boun1)
    assert_equal pt1[2],           pa1
    refute_equal pt1[2].object_id, pa1.object_id, "New one should be given a different object_id (unicode_normalized)"

    pt2 = pt1.dup
    refute_equal pt1.object_id,          pt2.object_id
    refute_equal pt1.instance.object_id, pt2.instance.object_id
    assert_equal pt1[2].object_id,       pt2[2].object_id
    assert_equal pt1.paras[1].object_id, pt2[2].object_id
    assert_equal pt1.paras[1].object_id, pt2.paras[1].object_id
    assert_equal pt1.boundaries[1].object_id, pt2.boundaries[1].object_id

    pa2 = pa1.dup
    assert_equal pa1,   pa2
    refute_equal pa1.object_id,          pa2.object_id
    refute_equal pa1.instance.object_id, pa2.instance.object_id
    pa2.replace("x")
    refute_equal pa1,   pa2

    bo2 = bo1.dup
    assert_equal bo1,   bo2
    refute_equal bo1.object_id,          bo2.object_id
    refute_equal bo1.instance.object_id, bo2.instance.object_id
    bo2.replace("x")
    refute_equal bo1,   bo2
  end

  def test_deepcopy
    para1 = [Pt::Paragraph.new("a"), Pt::Paragraph.new("b"), Pt::Paragraph.new("c")]
    boun1 = [Pt::Boundary.new("\n"), Pt::Boundary::MyA.new("\n===\n"), Pt::Boundary.new("\n")]
    pt1 = Pt.new(para1, boun1)
    pt2 = pt1.deepcopy
    assert_equal pt1, pt2
    assert_equal Pt::Paragraph,     pt1.to_a[0].class
    assert_equal Pt::Boundary,      pt1.to_a[1].class
    assert_equal Pt::Paragraph,     pt1.to_a[2].class
    assert_equal Pt::Boundary::MyA, pt1.to_a[3].class
    assert_equal "Boundary::MyA", pt1.to_a[3].subclass_name, "subclass_name should be equal: pt1: #{pt1.to_a[3].inspect}"
    assert_equal "Boundary::MyA", pt2.to_a[3].subclass_name
    refute_equal pt1.object_id,         pt2.object_id
    refute_equal pt1.to_a[3].object_id, pt2.to_a[3].object_id
    refute_equal pt1.to_a[3].to_s.object_id, pt2.to_a[3].to_s.object_id
    refute_equal pt1.to_a[4].object_id, pt2.to_a[4].object_id
    refute_equal pt1.to_a[4].to_s.object_id, pt2.to_a[4].to_s.object_id
  end

  def test_insert
    a1  = ["a", "\n\n\n", "b", "\n\n\n", "c"]
    pt1 = Pt.new(a1)
    assert_equal 6, pt1.size,       "Sanity check 1"
    assert_equal a1+[""], pt1.to_a, "Sanity check 2"
    pt2 = pt1.deepcopy
    err = assert_raises(IndexError){ pt2.insert(-99, ?d, "\n") }
    assert_raises(IndexError){ pt2.insert(-99) }
    assert_match(/\btoo small for array\b/i, err.message)
    assert_raises(IndexError){ pt2.insert(7, ?d, "\n") }
    assert_raises(ArgumentError){ pt2.insert(-1, ?d) }
    assert_raises(ArgumentError){ pt2.concat([?d]) }
    assert_raises(ArgumentError){ pt2.push(   ?d) }
    assert_raises(ArgumentError){ pt2.insert(-1, ?d, "", ?e) }
    assert_raises(TypeError){ pt2.insert(-1, Pt::Boundary.new("\n"), Pt::Paragraph.new(?d)) }
    assert_raises(TypeError){ pt2.insert(-1, Pt::Paragraph.new(?d),  Pt::Paragraph.new(?d)) }
    assert_raises(TypeError){ pt2.insert(-2, Pt::Paragraph.new(?d),  Pt::Boundary.new("\n")) }
    assert_raises(TypeError){ pt2.insert(-2, Pt::Boundary.new("\n"), Pt::Boundary.new("\n")) }
    assert_raises(TypeError){ pt2.insert(-2, Pt.new([?d]), Pt::Boundary.new("\n")) }
    pt2 = pt1.deepcopy  # required, as @array is altered.
    assert_equal pt1, pt2
    assert_equal pt1, pt2.insert(-1), "Insert with no second arguments should alter nothing."
    assert_equal pt1, pt2.insert(0)
    assert_equal pt1, pt2.insert(1)

    pt2.insert(-1, ?e, "\n")
    assert_equal 8, pt2.size
    assert_equal [?e, "\n"], pt2.to_a[-2..-1]
    assert pt2[-2].paragraph?
    assert pt2[-1].boundary?

    bo5 = Pt::Boundary.new("==")
    pt2.insert(5, bo5, ?d)
    assert_equal 10, pt2.size
    assert_equal ["==", ?d, "", ?e, "\n"], pt2.to_a[-5..-1]
    assert pt2[-2].paragraph?
    assert pt2[-1].boundary?
    assert_equal bo5, pt2[5]
    assert pt2[5].boundary?
    assert_equal "d", pt2[6]
    assert pt2[6].paragraph?

    pt2.insert(2, pt1, "")
    assert_equal 12, pt2.size
    assert_equal "a\n\n\na\n\n\nb\n\n\ncb\n\n\nc==de\n", pt2.join
end

  def test_array_methods
    a1  = ["a", "\n\n\n", "b", "\n\n\n", "c"]
    pt1 = Pt.new(a1)
    assert_equal 6, pt1.size
    assert_equal a1+[""], pt1.to_a
    assert_raises(NoMethodError){ pt1.delete_at(0) }
    assert_raises(NoMethodError){ pt1 << ?d }
  end

    #assert ( /_rails_db\.sql$/ =~ s1.outfile )
    #assert_nil            fkeys
end	# class TestUnitPlainTextPart < MiniTest::Test

#end	# if $0 == __FILE__

