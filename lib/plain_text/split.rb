# -*- coding: utf-8 -*-

module PlainText
  #
  # Contains a method that splits a String in a reversible way
  #
  # String#split is a powerful method.
  # One caveat is there is no way to guarantee the possibility to reverse
  # the process when a *random* Regexp (as opposed to String or when the user
  # knows what exactly the Regexp is or has a perfect control about it) is given,
  # because the resultant Array contains *all* the group-ed String as elements.
  #
  # This module provides a method to enable it.  Requiring this file
  # makes the method included in the String class.
  #
  # @example Reversible (the method is assumed to be included in String)
  #   my_str.split_with_delimiter(/MyRegexp/).join == my_str  # => true
  #
  # @author Masa Sakano (Wise Babel Ltd)
  #
  module Split

    # The class-method version of the instance method of the same name.
    #
    # One more parameter (input String) is required to specify.
    #
    # @param instr [String] String that is examined.
    # @param re_in [Regexp, String] If String, it is interpreted literally as in String#split.
    # @return [Array]
    # @see PlainText::Split#split_with_delimiter
    def self.split_with_delimiter(instr, re_in)
      re_in = Regexp.new(Regexp.quote(re_in)) if re_in.class.method_defined? :to_str
      re_grp = add_grouping(re_in)  # Ensure grouping.

      arspl = instr.split re_grp, -1
      return arspl if arspl.size <= 1  # n.b., Size is 0 for an empty string (only?).

      n_grouping = re_grp.match(instr).size  # The number of grouping - should be at least 2, including $&.
      return adjust_last_element(arspl) if n_grouping <= 2

      # Takes only the split main contents and delimeter
      arret = []
      arspl.each_with_index do |ec, ei|
        arret << ec if (1..2).include?( (ei + 1) % n_grouping )
      end
      adjust_last_element(arret) # => Array
    end

    # The class-method version of the instance method of the same name.
    #
    # One more parameter (input String) is required to specify.
    #
    # @param instr [String] String that is examined.
    # @param re_in [Regexp, String] If String, it is interpreted literally as in String#split.
    # @param like_linenum [Boolean] if true (Def: false), it counts like the line number.
    # @param with_if_end [Boolean] a special case (see the description).
    # @return [Integer] always positive
    # @see PlainText::Split#count_regexp
    def self.count_regexp(instr, re_in, like_linenum: false, with_if_end: false)
      like_linenum = true if with_if_end
      return (with_if_end ? [0, true] : 0) if instr.empty?
      allsize = split_with_delimiter(instr, re_in).size

      n_normal = allsize.div(2)
      return n_normal if !like_linenum
      n_lines = (allsize.even? ? allsize : allsize+1).div 2
      with_if_end ? [n_normal, (n_normal ==  n_lines)] : n_lines
    end

    # The class-method version of the instance method of the same name.
    #
    # One more parameter (input String) is required to specify.
    #
    # @param instr [String] String that is examined.
    # @param linebreak [String] +\n+ etc (Default: $/).
    # @return [Integer] always positive
    # @see #count_lines
    def self.count_lines(instr, linebreak: $/)
      return 0 if instr.empty?
      ar = instr.split(linebreak, -1)  # -1 is specified to preserve the last linebreak(s).
      ar.pop if "" == ar[-1]
      ar.size
    end

    ####################################################
    # Class methods (Private)
    ####################################################

    # This method encloses the given Regexp with '()'
    #
    # @param rule_re [Regexp]
    # @return [Regexp]
    def self.add_grouping(rule_re)
      Regexp.new '('+rule_re.source+')', rule_re.options
    end
    private_class_method :add_grouping

    # Utility
    def self.adjust_last_element(ary)
      ary.pop if ary[-1].empty?  # ary.size > 0 is guaranteed
      ary
    end
    private_class_method :adjust_last_element

    ####################################################
    # Instance methods
    ####################################################

    # Split with the delimiter even when Regexp (or String) is given
    #
    # Note the last empty component, if exists, is deleted in the returned Array.
    # If the input string is empty, the returned Array is also empty,
    # as in String#split.
    #
    # @example Standard split (without grouping) : +s="XQabXXcXQ"+
    #   s.split(/X+Q?/)         #=> ["", "ab", "c"],                   
    #   s.split(/X+Q?/, -1)     #=> ["", "ab", "c", ""],               
    #
    # @example Standard split (with grouping) : +s="XQabXXcXQ"+
    #   s.split(/X+(Q?)/, -1)   #=> ["", "Q", "ab", "", "c", "Q", ""], 
    #   s.split(/(X+(Q?))/, -1) #=> ["", "XQ", "Q", "ab", "XX", "", "c", "XQ", "Q", ""], 
    #
    # @example This method (when included in String (as Default)) : +s="XQabXXcXQ"+
    #   s.split_with_delimiter(/X+(Q?)/)
    #                           #=> ["", "XQ", "ab", "XX", "c", "XQ"]
    #
    # @param rest [Regexp, String] If String, it is interpreted literally as in String#split.
    # @return [Array]
    def split_with_delimiter(*rest)
      PlainText::Split.public_send(__method__, self, *rest)
    end

    # Count the number of matches to self that satisfy the given Regexp
    #
    # If like_linenum option is specified, it is counted like the number of
    # lines, namely the returned value is incremented from the number of
    # matches by 1 unless the very last characters of the String is
    # the last match.
    # For example, if no matches are found, this still returns one.
    #
    # Note if the String (self) is empty, this always returns 0.
    #
    # The special option is +with_if_end+.  If given true,  
    # this returns Array<Integer, Boolean> instead of a simple Integer,
    # with the first parameter being the Integer of the count as with
    # the default like_linenum=false, and the second parameter gives
    # true if the number is the same even if it was like_linenum=true,
    # namely if the end of the String coincides with the last match,
    # else false.
    # (This parameter is introduced just to reduce the overhead of
    # potentially calling this routine twice or user's making their own check.)
    #
    # @param rest [Regexp, String] re_in: If String, it is interpreted literally as in String#split.
    # @param kwd [Hash<like_linenum: Boolean, with_if_end: Boolean>]
    #    if like_linenum: true (Def: false), it counts like the line number.
    #    with_if_end: a special case (see the description).
    # @return [Integer, Array<Integer, Boolean>] always positive
    # @see PlainText::Split#count_regexp
    def count_regexp(*rest, **kwd)
      PlainText::Split.public_send(__method__, self, *rest, **kwd)
    end

    # Returns the number of lines.
    #
    # @param kwd [Hash<linebreak: String>] +\n+ etc (Default: $/).
    # @return [Integer] always positive
    # @see PlainText::Split#count_regexp
    def count_lines(**kwd)
      PlainText::Split.public_send(__method__, self, **kwd)
    end
  end # module Split
end # module PlainText

class String
  # Enabling String#split_with_delimiter
  include PlainText::Split
end

