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
    assert_equal ap1,   pt1.parts
    assert_equal ab1,   pt1.boundaries
    assert_equal a1,    pt1.to_a
    assert_operator a1,  '!=', pt1
    assert_operator pt1, '!=', a1

    pt2 = Pt.new(a2)
    assert_equal a2[0], pt2[0]
    assert_equal a2[2], pt2[2]
    assert_equal ap2,   pt2.parts
    assert_equal ab2,   pt2.boundaries
    assert_equal a2+[""], pt2.to_a  # An empty String is appended.
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
    assert_equal pt11, pt12
    pt21 = Pt.new(a2)
    pt22 = Pt.new(ap2, ab2)
    assert_equal pt21, pt22
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
    assert_operator a1,  '==', pt1.to_a
    assert_operator a1,  '!=', pt1
    assert_operator pt1, '!=', a1
    assert_operator a1,  '!=', ?a
    assert_operator ?a,  '!=', a1
    assert_operator pt1, '!=', pt2
    assert_operator pt2, '!=', pt1
    assert_operator pt1, '!=', ?a
    assert_operator ?a,  '!=', pt1
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
    assert_operator pt1[0, 6], :!=, a1
    assert_operator a1,        :!=, pt1[0, 6]

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
    assert_equal pt1.parts[0, 2],      pt2.parts
    assert_equal pt1.boundaries[0, 2], pt2.boundaries

    # negative or too-big out-of-bound begin
    assert_nil   a1[-99..2]
    assert_nil   pt1[-99..2]
    assert_nil   pt1[-99..-1]
    assert_nil   pt1[98..99]

    # other out-of-bounds: Empty
    assert_equal Pt.new([]),  pt1[2..1]
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
    assert_equal    pt1.class, ptp.class  # PlainText::Part
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


  # Tests of Part.parse
  def test_parse01
    s1 = "a\n\n\nb\n\n\nc\n\n"
    pt1 = Pt.parse s1
    assert_equal 6, pt1.size
    assert_equal 3, pt1.parts.size
    assert_equal %w(a b c), pt1.parts
    assert_equal Pt::Paragraph, pt1[0].class
    assert_equal Pt::Boundary,  pt1[1].class
    assert_equal s1,  pt1.join
  end

    #assert ( /_rails_db\.sql$/ =~ s1.outfile )
    #assert_nil            fkeys
    #assert_match(/^\s*ADD CONSTRAINT/ , s1.instance_eval{ @strall })
end	# class TestUnitPlainTextPart < MiniTest::Test

#end	# if $0 == __FILE__

