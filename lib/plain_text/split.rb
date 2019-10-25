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
    # @param re_in [Regexp, String] If String, it is interpreted literally as in String#split.
    # @return [Array]
    def split_with_delimiter(*rest)
      PlainText::Split.public_send(__method__, self, *rest)
    end
  end # module Split
end # module PlainText

class String
  # Enabling String#split_with_delimiter
  include PlainText::Split
end

