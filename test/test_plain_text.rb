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

class TestUnitPlainText < MiniTest::Test
  T = true
  F = false
  SCFNAME = File.basename(__FILE__)
  PT = PlainText

  class ChString < String
    # Test sub-class.
  end

  def setup
  end

  def teardown
  end

  def test_clean_text01
    assert_raises(ArgumentError){ PT.clean_text("abc\n\ndef\n\n", trailing_s: false) }
  end

  def test_clean_text02
    assert_equal  3, PT.clean_text("abc").size
    assert_equal  7, PT.clean_text("abc\ndef").size
    assert_equal  8, PT.clean_text("abc\ndef\n").size
    assert_equal  8, PT.clean_text("abc\ndef\n\n").size
    assert_equal  8, PT.clean_text("abc\ndef\n\n\n").size

    s0 = "abc\n\ndef\n\n"

    sr = PT.clean_text(s0)
    assert_equal s0[0..-2], sr, "#{s0[0..-2].inspect}(Expected) != #{sr.inspect}"
    sr = PT.clean_text(s0, lastsps_style: :delete)  # preserve_paragraph=true
    assert_equal s0[0..-3], sr
    sr = PT.clean_text(s0, lbs_style: :delete, lastsps_style: :delete, lb_out: "\n")  # preserve_paragraph=true
    assert_equal s0[0..-3], sr, "#{s0[0..-3].inspect}(Expected) != #{sr.inspect}"

    s2 = "abcXXdefXX"
    sr = PT.clean_text(s0, lbs_style: :delete, lastsps_style: :none, lb_out: "X")  # preserve_paragraph=true
    assert_equal s2, sr, "#{s2.inspect}(Expected) != #{sr.inspect}" 

    s1 = "abc\n\n\ndef\n\n\n"
    s2 = "abcdef"
    assert_equal s2, PT.clean_text(s1, preserve_paragraph: false, lbs_style: :delete, lastsps_style: :none)

    s2 = "abc\n\ndef\n\n"
    sr = PT.clean_text(s1, lbs_style: :delete, lastsps_style: :none)  # preserve_paragraph=true
    assert_equal s2, sr, "#{s2.inspect}(Expected) != #{sr.inspect}"

    s2 = "abcXYZdefXYZ"
    sr = PT.clean_text(s1, lbs_style: :delete, lastsps_style: :none, boundary_style: "XYZ")  # preserve_paragraph=true
    assert_equal s2, sr, "#{s2.inspect}(Expected) != #{sr.inspect}"

    s2 = "あいうえお"
    assert_equal s2, PT.clean_text("あいう\nえお\n", lbs_style: :delete, lastsps_style: :delete)  # preserve_paragraph=true
  end

  def test_clean_text03
    assert_raises(ArgumentError){ PT.clean_text("abc", boundary_style: nil) }
    s1  = "abc  \n  \n  def\n\n"
    s20 = "abc\n  \ndef\n"
    s21 = "abcXYZdefXYZ"
    s22 = "abc\n\ndef\n"
    sr = PT.clean_text(s1, boundary_style: :none)
    assert_equal s20, sr, prerr(s20, sr)
    sr = PT.clean_text(s1, boundary_style: "XYZ")
    assert_equal s21, sr, prerr(s21, sr)
    sr = PT.clean_text(s1, boundary_style: :truncate)
    assert_equal s22, sr, prerr(s22, sr)
  end

  def test_clean_text_lastsps_style01
    assert_raises(ArgumentError){ PT.clean_text("abc", lastsps_style: nil) }
    s1  = "\nabc\n\ndef\n"
    s20 =   "abc\n\ndef\n"
    s21 =   "abc\n\ndef"
    s22 =   "abc\n\ndefTT"

    sr = PT.clean_text(s1)
    assert_equal s20, sr, prerr(s20, sr)
    sr = PT.clean_text(s1, lastsps_style: :none)
    assert_equal s20, sr, prerr(s20, sr)
    sr = PT.clean_text(s1, lastsps_style: :delete)
    assert_equal s21, sr, prerr(s21, sr)
    sr = PT.clean_text(s1, lastsps_style: 'TT')
    assert_equal s22, sr, prerr(s22, sr)

    s3  = "\nabc\n\ndef"
    s41 =  " abc\n\ndefTT"
    s42 = "\nabc\n\ndef"
    sr = PT.clean_text(s3, firstsps_style: :truncate, lastsps_style: 'TT')
    assert_equal s41, sr, prerr(s41, sr)
    sr = PT.clean_text(s3, firstsps_style: :none,     lastsps_style: :delete)
    assert_equal s42, sr, prerr(s42, sr)
  end

  def test_clean_text_boundary01
    assert_raises(ArgumentError){ PT.clean_text("abc", boundary_style: nil) }
    s1  = "\n  ab\n  \ncd\n \n  \n ef\n \n  \n   \n  gh\n \n \n \n"
    s21 =    " ab\n  \ncd\n \n  \n ef\n \n  \n   \n  gh\n"
    s22 = "\n  ab\n\ncd\n\n ef\n\n  gh\n\n"
    s23 =  "\n ab\n\ncd\n\n\n ef\n\n\n gh\n\n\n"
    sr = PT.clean_text(s1, boundary_style: :n,  lastsps_style: :t, linehead_style: :n, firstsps_style: :t, sps_style: :n)
    assert_equal s21, sr, prerr(s21, sr)
    sr = PT.clean_text(s1, boundary_style: :t,  lastsps_style: :n, linehead_style: :n, firstsps_style: :n, sps_style: :n)
    assert_equal s22, sr, prerr(s22, sr)
    sr = PT.clean_text(s1, boundary_style: :t2, lastsps_style: :n, linehead_style: :t, firstsps_style: :n, sps_style: :n)
    assert_equal s23, sr, prerr(s23, sr)
  end

  def test_clean_text_part01
    s0  = "\n  \n abc\n\n \ndef\n\n \n\n"
    s1  = "TTabc\n\ndef\n"
    p00 = PT::Part.parse s0
    p0  = PT::Part.parse s0
    sr = PT.clean_text(s0, firstsps_style: 'TT')
    assert_equal s1, sr, prerr(s1, sr)
    sr = PT.clean_text(p0, firstsps_style: 'TT')
    assert_equal PT::Part, sr.class
    assert_equal s1,  sr.join
    assert_equal p00, p0, prerr(p00, p0)  # p0 is deepcopied?
  end

  def test_count_char02
    assert_equal  3, PT.count_char("abc")
    assert_equal  6, PT.count_char("abc\ndef")
    assert_equal  6, PT.count_char("abc\ndef\n")
    assert_equal  6, PT.count_char("abc\ndef\n\n")
    assert_equal  6, PT.count_char("abc\ndef\n\n\n")

    assert_equal  3, PT.count_char("abc")
    assert_equal  3, PT.count_char("abc\n")
    assert_equal  3, PT.count_char("abc\n\n")
    assert_equal  8, PT.count_char("abc\n\ndef")
    assert_equal  8, PT.count_char("abc\n\ndef\n")
    assert_equal  8, PT.count_char("abc\n\ndef\n\n")
    assert_equal  8, PT.count_char("abc\n\ndef\n\n\n")
  end

  def test_head01
    assert_raises(TypeError){ PT.head("abc", :wrong) }

    s = "\n2\n\n四\n5\n6\n\n8\n9\n10\n11\n\n13\n14\n15\n16\n\n18\n19\n\n"
    assert_equal s.sub(/(([^\n]*\n){#{PT::DEF_HEADTAIL_N_LINES}}).*/m, '\1'), PT.head(s) # 10 lines
    s  = "\nab四\n\n\nd\nef"
    s1 = "\nab四\n\n"
    s2 =          "\nd\nef"
    assert_equal s1, PT.head(s, 3)
    assert_equal s2, PT.head_inverse(s, 3)

    # char & byte options
    assert_equal s1, PT.head(s,   6, unit: :char)
    assert_equal "", PT.head("",  8, unit: :char)
    assert_equal ?a, PT.head(?a,  8, unit: :char)
    assert_equal s1, PT.head(s,   8, unit: :byte)
    assert_equal s1, PT.head(s,   8, unit: '-c')
    assert_equal ?a, PT.head(?a,  8, unit: :byte)
    assert_equal "", PT.head("", 10, unit: :byte)
  end


  def test_head_re02
    s  = "\n\n\n 04==\n\n 06==\n07\n08\n\n10\n11\n12\n14\n\n16\n17\n18\n19\n\n21\n22\n\n\n"
    s1 = "\n\n\n 04==\n"
    s2 =               "\n 06==\n07\n08\n\n10\n11\n12\n14\n\n16\n17\n18\n19\n\n21\n22\n\n\n"
    assert_equal s1, PT.head(s, /==/) # Up to Line 4
    assert_equal s2, PT.head_inverse(s, /==/) # From Line 5
  end

  def test_head_re03
    s  = "\n2\n\n四\n5\n6\n\n8\n9\n10\n1T\n\n13\n14\n15\n16\n\n壱T\n19\n\n"
    s3 = "\n2\n\n四\n5\n6\n\n8\n9\n10\n1T\n\n13\n14\n15\n16\n\n"
    s4 =                                                      "壱T\n19\n\n"
    s5 = "\n2\n\n四\n5\n6\n\n8\n9\n10\n"
    s6 = "\n2\n\n四\n5\n6\n\n8\n9\n"
    s7 = "\n2\n\n四\n5\n6\n\n8\n9\n10\n1T\n"
    assert_equal s3, PT.head(s, /壱/, inclusive: false), s4.inspect+" <=> \n"+PT.head(s, /壱/, inclusive: false).inspect # Up to 17
    assert_equal s6, PT.head(s, /1/ , inclusive: false), s6.inspect+" <=> \n"+PT.head(s, /1/ , inclusive: false).inspect # Up to 9
    assert_equal s4, PT.head_inverse(s, /壱/, inclusive: false) # After 17
    assert_equal s5, PT.head(s, /1/), s5.inspect+" <=> \n"+PT.head(s, /1/).inspect # Up to 9
    assert_equal s7, PT.head(s, /T/), s7.inspect+" <=> \n"+PT.head(s, /T/).inspect # Up to 11
  end

  def test_tail01
    assert_equal "",    PT.tail("")
    assert_equal 'abc', PT.tail("abc")
    assert_raises(TypeError){     PT.tail("abc", :wrong) }
    assert_raises(ArgumentError){ PT.tail("abc", 0) }

    s = "\n2\n\n四\n5\n6\n\n8\n9\n10\n11\n\n13\n14\n15\n16\n\n壱8\n19\n\n"

    s2 = s.sub(/.*11/m, '11')
    assert_equal s2, PT.tail(s), s2.inspect+' <=> '+PT.tail(s).inspect # 10 lines
    assert_equal s2.sub(/.\z/m, "X"), PT.tail(s.sub(/.\z/m, "X"))  # Ending with no linebreak
    se = "\n壱8\n19\n\n"
    assert_equal se, PT.tail(s, 4), se.inspect+" <=> \n"+PT.tail(s,4).inspect
    assert_equal se[1..-1], PT.tail(s, 3)
    assert_equal se[1..-1], PT.tail(s, 3, unit: '-n')

    # char & byte options
    assert_equal se, PT.tail(s,   8, unit: :char)
    assert_equal "", PT.tail("",  8, unit: :char)
    assert_equal ?a, PT.tail(?a,  8, unit: :char)
    assert_equal se, PT.tail(s,  10, unit: :byte)
    assert_equal se, PT.tail(s,  10, unit: '-c')
    assert_equal ?a, PT.tail(?a,  8, unit: :byte)
    assert_equal "", PT.tail("", 10, unit: :byte)

    # Negative index
    assert_equal s,  PT.tail(s, -1)
    assert_equal "", PT.tail(s, -100)

    assert_equal PT.head(s, 17), PT.tail_inverse(s, 3)
    assert_equal "", PT.tail_inverse("", 3)

    # Child class of String
    chs = ChString.new ""
    nam = chs.class.name
    assert_equal "", chs
    assert_equal chs, PT.tail(chs)
    assert_equal nam, PT.tail(chs).class.name, nam+" <=> \n"+PT.tail(chs).class.name.inspect
    assert_equal nam, PT.tail(chs.class.name)
    assert_equal nam, PT.tail(chs, -100).class.name
  end

  def test_tail_re02
    s  = "\n2\n\n四\n5\n6\n\n8\n9\n10\n11\n\n13\n14\n15\n16\n\n壱8\n19\n\n"
    s1 = "\n2\n\n四\n5\n6\n\n8\n9\n10\n11\n\n13\n14\n15\n"
    s2 =                                                "16\n\n壱8\n19\n\n"
    assert_equal s2, PT.tail(s, /16/), s2.inspect+" <=> \n"+PT.tail(s, /16/).inspect # After 15
    assert_equal s1, PT.tail_inverse(s, /16/) # Up to 15
    assert_equal s2, PT.tail(s, /15/, inclusive: false), s2.inspect+" <=> \n"+PT.tail(s, /15/, inclusive: false).inspect # After 16

    s3 = "\n2\n\n四\n5\n6\n\n8\n9\n10\n11\n\n13\n14\n15\n16\n\n"
    s4 =                                                      "壱8\n19\n\n"
    assert_equal s4, PT.tail(s, /壱/), s4.inspect+" <=> \n"+PT.tail(s, /壱/).inspect # After 17
    assert_equal s4, PT.tail(s, /8/),  s4.inspect+" <=> \n"+PT.tail(s, /8/ ).inspect # After 17
    assert_equal s3, PT.tail_inverse(s, /壱/) # Up to 17
    assert_equal s2, PT.tail(s, /5/,  inclusive: false), s2.inspect+" <=> \n"+PT.tail(s, /5/, inclusive: false).inspect # After 16
  end

  def test_tail_re03
    # Boundary condition tests - when the first line is included!
    s  = "abc\ndef"
    assert_equal     s, PT.tail(s, /a/), prerr(s, PT.tail(s, /a/), long: nil)
    assert_equal     s, PT.tail(s, /a/), prerr(s, PT.tail(s, /a/))
    assert_equal     s, PT.tail(s, /b/), prerr(s, PT.tail(s, /b/))
    assert_equal "def", PT.tail(s, /a/, inclusive: false)
    assert_equal "def", PT.tail(s, /b/, inclusive: false), prerr('"def"', PT.tail(s, /b/, inclusive: false))
  end

  # @param *rest [Object] Parameters to print.  Expected first, Actual second.
  # @param long: [Boolena] If true, linefeed is inserted (Better for String comparison).
  # @return [String] Error message when failed.
  def prerr(*rest, long: true)
    '[期待] '+rest.map(&:inspect).join(" ⇔ "+(long ? "\n" : "")+'[実際] ')
  end
end	# class TestUnitPlainText < MiniTest::Test

#end	# if $0 == __FILE__

