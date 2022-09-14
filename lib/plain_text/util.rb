# -*- coding: utf-8 -*-

module PlainText

  # Contains some utility methods for use in this module and classes.
  #
  # @author Masa Sakano (Wise Babel Ltd)
  #
  module Util

    # All methods in this Module are module functions.
    module_function 

    private

    # Make the Array of Ranges from an Array of positive Integers
    #
    # @example
    #    arind2ranges [1,2,3,6,7,9]
    #    # => [(1..3), (6..7), (9..9)]
    #
    # @param arin [Array<Integer>]
    # @return [Array<Range>]
    def arind2ranges(arin)
      arout = []
      (curi = curf = arin[0]) || raise("arin should not be empty.")
      arin.each do |i|
        if i > curf + 1
          arout.push(curi..curf)
          curi = curf = i
        else
          curf = i
        end
      end
      arout.push(curi..curf)
      arout  
    end
    private :arind2ranges

    # Returns a pair of Arrays of even and odd number-indices of the original Array
    #
    # @example
    #    even_odd_arrays([33,44,55], size_even: true)
    #    # => [[33, 55], [44, ""]]
    #
    # @param ary [Array]
    # @param size_even [Boolean] if true (Def: false), the sizes of the returned arrays are guaranteed to be identical.
    # @param filler [Object] if size_even: is true and if matching is performed, this filler is added at the end of the last element.
    def even_odd_arrays(ary, size_even: false, filler: "")
      ar_even = ary.select.with_index { |_, i| i.even? } rescue ary.select.each_with_index { |_, i| i.even? } # Rescue for Ruby 2.1 or earlier
      ar_odd  = ary.select.with_index { |_, i| i.odd? }  rescue ary.select.each_with_index { |_, i| i.odd? }  # Rescue for Ruby 2.1 or earlier
      if size_even && (ar_even.size != ar_odd.size)
        ar_odd.push filler
        raise "Should not happern." if (ar_even.size != ar_odd.size)
      end
      [ar_even, ar_odd]
    end

    # Returns a non-negative Array index for self
    #
    # If positive or zero, it returns i.
    # If the negative index is out of range, it returns nil.
    #
    # @see #positive_array_index_checked
    # @param i [Integer]
    # @param arysize [Array, Integer] Reference Array or its size (Array#size).
    # @return [Integer, NilClass] nil if out of range to the negative.  Note in most cases in Ruby default, it raises IndexError.  See the code of {#positive_array_index_checked}
    # @raise [TypeError] if non-integer is specified.
    # @raise [ArgumentError] if arysize is neither an Array nor Integer, or more specifically, it does not have size method or arysize.size does not return Integer or similar.
    def positive_array_index(i, arysize=nil)
      arysize = (arysize.respond_to?(:to_int) ? arysize.to_int : arysize.size)
      i2 = i.to_int rescue (raise TypeError, sprintf("no implicit conversion of #{i.class} into Integer (i=#{i.inspect},arysize=#{arysize.inspect})"))
      return i2 if i2 >= 0
      ret = arysize + i2 rescue (raise ArgumentError, "Reference is neither an Array nor Integer.")
      (ret < 0) ? nil : ret
    end
  
  
    # Returns a non-negative Array index for self, performing a check.
    #
    # Exception is raised if it is out of range.
    #
    # Wrapper for {#positive_array_index}
    #
    # @param index_in [Integer] Index to check and convert from. Potentially negative integer.
    # @param arysize [Array, Integer] Reference Array or its size (Array#size).
    # @param accept_too_big [Boolean, NilClass] if true (Default), a positive index larger than the last array index is returned as it is. If nil, the last index + 1 is accepted but raises an Exception for anything larger.  If false, any index larger than the last index raises an Exception.
    # @param varname [NilClass, String] Name of the variable (or nil) to be used for error messages.
    # @return [Integer] Non-negative index; i.e., if index=-1 is specified for an Array with a size of 3, the returned value is 2 (the last index of it).
    # @raise [IndexError] if the index is out of the range to negative.
    # @raise [ArgumentError] if arysize is neither an Array nor Integer, or more specifically, it does not have size method or arysize.size does not return Integer or similar.
    def positive_array_index_checked(index_in, arysize, accept_too_big: true, varname: nil)
      # def self.positive_valid_index_for_array(index_in, arysize, varname: nil)
      errmsgs = {}
      %w(of for).each do |i|
        errmsgs[i] = (varname ? "." : sprintf(" %s %s.", i, varname)) 
      end
  
      arysize = (arysize.respond_to?(:to_int) ? arysize.to_int : arysize.size)
      index = positive_array_index(index_in, arysize)  # guaranteed to be Integer or nil (or ArgumentError)
      raise IndexError, sprintf("index (%s) too small for array; minimum: -%d", index_in, arysize) if !index  # Ruby default Error message (except the variable "index" as opposed to "index_in is used in the true Ruby default).
      if index_in >= 0
        last_index = arysize - 1
        errnote1 = nil
        if    (index >  last_index + 1) && !accept_too_big
          errnote1 = ' (or +1)'
        elsif (index == last_index + 1) && (false == accept_too_big)
          errnote1 = " "
        end
        raise IndexError, sprintf("Specified index (%s) is larger than the last index (%d)%s%s", index_in, last_index, errnote1, errmsgs['of']) if errnote1
      end
      index
    end

    # Converts Array or Range to an Array with positive indices.
    #
    # @param from [Array, Range]
    # @param arref [Array, Integer] Reference Array or its size (Array#size) or nil (interpreted as self#size).
    # @param flatten [Boolean] If true (Default), if elements are Range, they are unfolded.  If false and if an Array containing a Range, Exception is raised.
    # @param sortuniq [Boolean] If true (Default), the return is sorted and uniq-ed.
    # @return [Array, nil] nil if arref is empty or if out of range to the negative.  Note in most cases in Ruby default, it raises IndexError.  See the code of {#positive_array_index_checked}
    # @raise [TypeError] if non-integer is specified.
    # @raise [ArgumentError] if arref is neither an Array nor Integer, or more specifically, it does not have size method or arref.size does not return Integer or similar.
    def to_ary_positive_index(from, arref, flatten: true, sortuniq: true, **kwd)
      arrefsize = (arref ? (arref.respond_to?(:to_int) ? arref.to_int : arref.size) : size)
      return nil if arrefsize < 1
      if flatten
        from = [from].flatten.map{|ec| like_range?(ec) ? send(__method__, ec, arrefsize, flatten: false, sortuniq: sortuniq, **kwd) : ec }.flatten
      end
      if like_range?(from)
        i_beg = positive_array_index_checked(from.begin, arrefsize, **kwd)
        n = from.end
        i_end = ((n.nil? || n == Float::INFINITY) ? arrefsize-1 : positive_array_index_checked(n, arrefsize, **kwd))
        return (from.exclude_end? ? (i_beg...i_end) : (i_beg..i_end)).to_a
      end
      ret = from.map{|i| positive_array_index_checked(i, arrefsize, **kwd)}
      (sortuniq ? ret.sort.uniq : ret) 
    end

    # Returns true if obj is like Range (duck-typing).
    #
    # @param obj [Object]
    def like_range?(obj)
      obj.respond_to? :exclude_end?
    end

    # Raise TypeError
    #
    # Call as +raise_typeerror(var_name)+ from instance methods,
    # providing this Module is included in the Class/Module.
    #
    # @param var [Object]
    # @param to_class [String, Class] class name converted into.
    # @option verbose: [Boolean] ($DEBUG)
    # @raise [TypeError]
    def raise_typeerror(var, to_class, verbose: $DEBUG)
      msg1 = (verbose ? sprintf("(<= %s)", var.inspect) : "")
      to_class_str = (to_class.name rescue to_class.to_str)
      raise TypeError, sprintf("no implicit conversion of %s%s into %s", var.class, msg1, to_class_str)
    end

  end # module Util

  include Util
end # module PlainText

