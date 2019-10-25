# -*- coding: utf-8 -*-

require "plain_text/util"

module PlainText

  # Class to represent a Chapter-like entity like an Array
  #
  # An instance of this class contains always an even number of elements,
  # either another {Part} instance or {Paragraph}-type String-like instance,
  # followed by a {Boundary}-type String-like instance.  The first element is
  # always a former and the last element is always a latter.
  #
  # Essentially, the instance of this class holds the order information between sub-{Part}-s (< Array)
  # and/or {Paragraph}-s (< String) and {Boundary}-s (< String).
  #
  # An example instance looks like this:
  #
  #   Part (
  #     (0) Paragraph::Empty,
  #     (1) Boundary::General,
  #     (2) Part::ArticleHeader(
  #           (0) Paragraph::Title,
  #           (1) Boundary::Empty
  #         ),
  #     (3) Boundary::TitleMain,
  #     (4) Part::ArticleMain(
  #           (0) Part::ArticleSection(
  #                 (0) Paragraph::Title,
  #                 (1) Boundary::General,
  #                 (2) Paragraph::General,
  #                 (3) Boundary::General,
  #                 (4) Part::ArticleSubSection(...),
  #                 (5) Boundary::General,
  #                 (6) Paragraph::General,
  #                 (7) Boundary::Empty
  #               ),
  #           (1) Boundary::General,
  #           (2) Paragraph::General,
  #           (3) Boundary::Empty
  #         ),
  #     (5) Boundary::General
  #   )
  #
  # A Section (Part) always has an even number of elements: pairs of ({Part}|{Paragraph}) and {Boundary} in this order.
  #
  # Note some standard destructive Array operations, most notably +#delete+, +#delete_if+, +#reject!+,
  # +#select!+, +#filter!+, +#keep_if+, +#flatten!+, +#uniq!+ may alter the content in a way
  # it breaks the self-inconsistency of the object.
  # Use it at your own risk, if you wish (or don't).
  #
  # An instance of this class is always *non-equal* to that of the standard Array class.
  # To compare it at the Array level, convert a {Part} class instance into Array with #to_a first and compare them.
  #
  # For CRUD of elements (contents) of an instance, the following methods are most basic:
  #
  # * Create:
  #   * Insert/Append: {#insert} to insert. If the specified index is #size}, it means "append". For primitive operations, specify +primitive: true+ to skip various checks performed to guarantee the self-consistency as an instance of this class.
  #   * {#<<} is disabled.
  # * Read:
  #   * Read: #to_a gives the standard Array, and then you can do whatever manipulation allowed for Array.  For example, if you delete an element in the returned Array, that does not affect the original {Part} instance.  However, it is a shallow copy, and hence if you alter an element of it destructively (such as String#replace), the original instance, too, is affected.
  #     * The methods {#[]} (or its alias {#slice}) have some restrictions, such as, an odd number of elements cannot be retrieved, so as to conform the returned value is a valid instance of this class.
  # * Update:
  #   * Replace: {#[]=} has some restrictions, such as, if multiple elements are replaced, they have to be pairs of Paragraph and Boundary.  To skip all the checks, do {#insert} with +primitive: true+
  # * Delete:
  #   * Delete: {#slice!} to delete. For primitive operations, specify +primitive: true+ to skip various checks performed to guarantee the self-consistency as an instance of this class.
  #     * +#delete_at+ is disabled. +#delete+, +#delete_if+, +#reject!+, +#select!+, +#filter!+, +#keep_if+ (and +#drop_while+ and +#take_whie+ in recent Ruby) remain enabled, but if you use them, make sure to use them carefully at your own risk, as no self-consistency checks would be performed automatically.
  #
  # @author Masa Sakano (Wise Babel Ltd)
  #
  # @todo methods
  #   * flatten
  #   * SAFE level  for command-line tools?
  #
  class Part < Array

    include PlainText::Util

    # Error messages
    ERR_MSGS = {
      even_num: 'even number of elements must be specified.',
      use_to_a: 'To handle it as an Array, use to_a first.',
    }

    # @param arin [Array] of [Paragraph1, Boundary1, Para2, Bd2, ...] or Part/Paragraph if boundaries is given
    # @param boundaries [Array] of Boundary
    # @option recursive: [Boolean] if true (Default), normalize recursively.
    # @option compact: [Boolean] if true (Default), pairs of nil paragraph and boundary are removed.  Otherwise, nil is converted to an empty string.
    # @option compacter: [Boolean] if true (Default), pairs of nil or empty paragraph and boundary are removed.
    # @return [self]
    def initialize(arin, boundaries=nil, recursive: true, compact: true, compacter: true)
      if !boundaries
        super(arin)
      else

        armain = []
        arin.each_with_index do |ea_e, i|
          armain << ea_e
          armain << (boundaries[i] || Boundary.new(''))
        end
        super armain
      end
      normalize!(recursive: recursive, compact: compact, compacter: compacter)
    end

    # Parses a given string (or {Part}) and returns this class of instance.
    #
    # @param inprm [String, Array, Part]
    # @option rule: [PlainText::ParseRule]
    # @return [PlainText::Part]
    def self.parse(inprm, rule: PlainText::ParseRule::RuleConsecutiveLbs)
      arin = rule.apply(inprm)
      self.new(arin)
    end

    ####################################################
    # Instance methods
    ####################################################

    ##########
    # Unique instance methods (not existing in Array)
    ##########

    # Returns an array of boundary parts (odd-number-index parts), consisting of Boundaries
    #
    # @return [Array<Boundary>]
    # @see #parts
    def boundaries
      select.with_index { |_, i| i.odd? } rescue select.each_with_index { |_, i| i.odd? } # Rescue for Ruby 2.1 or earlier
    end

    # returns all the Boundaries immediately before the index and at it as an Array
    #
    # See {#squash_boundary_at!} to squash them.
    #
    # @param index [Integer]
    # @return [Array, nil] nil if a too large index is specified.
    def boundary_extended_at(index)
      (i_pos = get_valid_ipos_for_boundary(index)) || return
      arret = []
      prt = self[i_pos-1]
      arret = prt.public_send(__method__, -1) if prt.class.method_defined? __method__
      arret << self[index]
    end

    # Returns a dup-ped instance with all the Arrays and Strings dup-ped.
    #
    # @return [Part]
    def deepcopy
      dup.map!{ |i| i.class.method_defined?(:deepcopy) ? i.deepcopy : i.dup }
    end

    # each method for boundaries only, providing also the index (always an odd number) to the block.
    #
    # For just looping over the elements of {#boundaries}, do simply
    #
    #   boundaries.each do |ec|
    #   end
    #
    # The indices provided in this method are for the main Array,
    # and hence different from {#boundaries}.each_with_index
    #
    # @param (see #map_boundaries_with_index)
    # @return as self
    def each_boundaries_with_index(**kwd, &bl)
      map_boundaries_core(map: false, with_index: true, **kwd, &bl)
    end

    # each method for parts only, providing also the index (always an even number) to the block.
    #
    # For just looping over the elements of {#parts}, do simply
    #
    #   parts.each do |ec|
    #   end
    #
    # The indices provided in this method are for the main Array,
    # and hence different from {#parts}.each_with_index
    #
    # @param (see #map_parts_with_index)
    # @return as self
    def each_parts_with_index(**kwd, &bl)
      map_parts_core(map: false, with_index: false, **kwd, &bl)
    end

    # The first significant (=non-empty) element.
    #
    # If the returned value is non-nil and destructively altered, self changes.
    #
    # @return [Integer, nil] if self.empty? nil is returned.
    def first_significant_element
      (i = first_significant_index) || return
      self[i]
    end

    # Index of the first significant (=non-empty) element.
    #
    # If every element is empty, the last index is returned.
    #
    # @return [Integer, nil] if self.empty? nil is returned.
    def first_significant_index
      return nil if empty?
      each_index do |i|
        return i if self[i] && !self[i].empty?  # self for sanity
      end
      return size-1
    end

    # True if the index should be semantically for Paragraph?
    #
    # @param i [Integer] index for the array of self
    # @option skip_check: [Boolean] if true (Default: false), skip conversion of the negative index to positive.
    # @see #parts
    def index_para?(i, skip_check: false)
      skip_check ? i.even? : positive_array_index_checked(i, self).even?
    end

    # The last significant (=non-empty) element.
    #
    # If the returned value is non-nil and destructively altered, self changes.
    #
    # @return [Integer, nil] if self.empty? nil is returned.
    def last_significant_element
      (i = last_significant_index) || return
      self[i]
    end

    # Index of the last significant (=non-empty) element.
    #
    # If every element is empty, 0 is returned.
    #
    # @return [Integer, nil] if self.empty? nil is returned.
    def last_significant_index
      return nil if empty?
      (0..(size-1)).to_a.reverse.each do |i|
        return i if self[i] && !self[i].empty?  # self for sanity
      end
      return 0
    end

    # map method for boundaries only, returning a copied self.
    #
    # If recursive is true (Default), any Boundaries in the descendant Parts are also handled.
    #
    # If a Boundary is set nil or empty, along with the preceding Paragraph,
    # the pair is removed from the returned instance in Default (:compact and :compacter options
    # - see {#initialize} for detail)
    #
    # @option recursive: [Boolean] if true (Default), map is performed recursively.
    # @return as self
    # @see #initialize for the other options (:compact and :compacter)
    def map_boundaries(**kwd, &bl)
      map_boundaries_core(with_index: false, **kwd, &bl)
    end

    # map method for boundaries only, providing also the index (always an odd number) to the block, returning a copied self.
    #
    # @param (see #map_boundaries)
    # @return as self
    def map_boundaries_with_index(**kwd, &bl)
      map_boundaries_core(with_index: true, **kwd, &bl)
    end

    # map method for parts only, returning a copied self.
    #
    # If recursive is true (Default), any Paragraphs in the descendant Parts are also handled.
    #
    # If a Paragraph is set nil or empty, along with the following Boundary,
    # the pair is removed from the returned instance in Default (:compact and :compacter options
    # - see {#initialize} for detail)
    #
    # @option recursive: [Boolean] if true (Default), map is performed recursively.
    # @return as self
    # @see #initialize for the other options (:compact and :compacter)
    def map_parts(**kwd, &bl)
      map_parts_core(with_index: false, **kwd, &bl)
    end

    # map method for parts only, providing also the index (always an even number) to the block, returning a copied self.
    #
    # @param (see #map_parts)
    # @return as self
    def map_parts_with_index(**kwd, &bl)
      map_parts_core(with_index: false, **kwd, &bl)
    end

    # Normalize the content, making sure it has an even number of elements
    #
    # The even and odd number elements are, if bare Strings or Array, converted into
    # Paeagraph and Boundary, or Part, respectively.  If not, Exception is raised.
    # Note nil is conveted into either an empty Paragraph or Boundary.
    #
    # @option recursive: [Boolean] if true (Default), normalize recursively.
    # @option ignore_array_boundary: [Boolean] if true (Default), even if a Boundary element (odd-numbered index) is an Array, ignore it.
    # @option compact: [Boolean] if true (Default), pairs of nil paragraph and boundary are removed.  Otherwise, nil is converted to an empty string.
    # @option compacter: [Boolean] if true (Default), pairs of nil or empty paragraph and boundary are removed.
    # @return [self]
    def normalize!(recursive: true, ignore_array_boundary: true, compact: true, compacter: true)
      # Trim pairs of consecutive Paragraph and Boundary of nil
      size_parity = (size.even? ? 0 : 1)
      if (compact || compacter) && (size > 0+size_parity)
        ((size-2-size_parity)..0).each do |i| 
          # Loop over every Paragraph
          next if i.odd?
          slice! i, 2 if compact   &&  !self[i] && !self[i+1]
          slice! i, 2 if compacter && (!self[i] || self[i].empty?) && (!self[i+1] || self[i+1].empty?)
        end
      end

      i = -1
      map!{ |ea|
        i += 1
        normalize_core(ea, i, recursive: recursive)
      }
      insert_original_b4_part(size, Boundary.new('')) if size.odd?
      self
    end

    # Non-destructive version of {#normalize!}
    #
    # @option recursive: [Boolean] if true (Default), normalize recursively.
    # @option ignore_array_boundary: [Boolean] if true (Default), even if a Boundary element (odd-numbered index) is an Array, ignore it.
    # @option compact: [Boolean] if true (Default), pairs of nil paragraph and boundary are removed.  Otherwise, nil is converted to an empty string.
    # @option compacter: [Boolean] if true (Default), pairs of nil or empty paragraph and boundary are removed.
    # @return as self
    # @see #normalize!
    def normalize(recursive: true, ignore_array_boundary: true, compact: true, compacter: true)
      # Trims pairs of consecutive Paragraph and Boundary of nil
      arall = to_a
      size_parity = (size.even? ? 0 : 1)
      if (compact || compacter) && (size > 0+size_parity)
        ((size-2-size_parity)..0).each do |i| 
          # Loop over every Paragraph
          next if i.odd?
          arall.slice! i, 2 if compact   &&  !self[i] && !self[i+1]
          arall.slice! i, 2 if compacter && (!self[i] || self[i].empty?) && (!self[i+1] || self[i+1].empty?)
        end
      end

      i = -1
      self.class.new(
        arall.map{ |ea|
          i += 1
          normalize_core(ea, i, recursive: recursive)
        } + (arall.size.odd? ? [Boundary.new('')] : [])
      )
    end


    # Returns an array of substantial parts (even-number-index parts), consisting of Part and/or Paragraph
    #
    # @return [Array<Part, Paragraph>]
    # @see #boundaries
    def parts
      select.with_index { |_, i| i.even? } rescue select.each_with_index { |_, i| i.even? } # Rescue for Ruby 2.1 or earlier
      # ret.freeze
    end

    # Reparses self or a part of it.
    #
    # @param str [String]
    # @option rule: [PlainText::ParseRule] (PlainText::ParseRule::RuleConsecutiveLbs)
    # @option name: [String, Symbol, Integer, nil] Identifier of rule, if need to specify.
    # @option range: [Range, nil] Range of indices of self to reparse. In Default, the entire self.
    # @return [self]
    def reparse!(rule: PlainText::ParseRule::RuleConsecutiveLbs, name: nil, range: (0..-1))
      insert range.begin, self.class.parse((range ? self[range] : self), rule: rule, name: name)
      self
    end

    # Non-destructive version of {reparse!}
    #
    # @param (see #reparse!)
    # @return [PlainText::Part]
    def reparse(**kwd)
      ret = self.dup
      ret.reparse!(**kwd)
      ret
    end


    # Emptifies all the Boundaries immediately before the Boundary at the index and squashes it to the one at it.
    #
    # See {#boundary_extended_at} to view them.
    #
    # @param index [Integer]
    # @return [Boundary, nil] nil if a too large index is specified.
    def squash_boundary_at!(index)
      (i_pos = get_valid_ipos_for_boundary(index)) || return
      prt = self[i_pos-1]
      m = :emptify_last_boundaries!
      self[i_pos] << prt.public_send(m) if prt.class.method_defined? m
      self[i_pos]
    end


    # Wrapper of {#squash_boundary_at!} to loop over the whole {Part}
    #
    # @return [self]
    def squash_boundaryies!
      each_boundaries_with_index do |ec, i|
        squash_boundary_at!(i)
      end
      self
    end


    # Boundary sub-class name only
    #
    # Make sure your class is a child class of Part
    # Otherwise this method would not be inherited, obviously.
    #
    # @example
    #   class PlainText::Part
    #     class Section < self
    #       class Subsection < self; end  # It must be a child class!
    #     end
    #   end
    #   ss = PlainText::Part::Section::Subsection.new ["abc"]
    #   ss.subclass_name  # => "Section::Subsection"
    #
    # @return [String]
    # @see PlainText::Part#subclass_name
    def subclass_name
      printf "__method__=(%s)\n", __method__
      self.class.name.split(/\A#{Regexp.quote method(__method__).owner.name}::/)[1] || ''
    end

    ##########
    # Overwriting instance methods of the parent Object or Array class
    ##########

    # Original equal and plus operators of Array
    hsmethod = {
      :equal_original_b4_part => :==,
      :substitute_original_b4_part => :[]=,
      :insert_original_b4_part    => :insert,
      :delete_at_original_b4_part => :delete_at,
      :slice_original_b4_part     => :slice,
      :slice_original_b4_part!    => :slice!,
    }

    hsmethod.each_pair do |k, ea_orig|
      if self.method_defined?(k)
        # To Developer: If you see this message, switch the DEBUG flag on (-d option) and run it.
        warn sprintf("WARNING: Method %s#%s has been already defined, which should not be.  Contact the code developer. Line %d in %s%s", self.name, k.to_s, __FILE__, __LINE__, ($DEBUG ? "\n"+caller_locations.join("\n").map{|i| "  "+i} : ""))
      else
        alias_method k, ea_orig
      end
    end

    alias_method :substit, :substitute_original_b4_part

    ########## Most basic methods (Object) ##########

    # @return [String]
    def inspect
      self.class.name + super
    end

    # # clone
    # #
    # # Redefines Array#clone so the instance variables are also cloned.
    # #
    # # @return [self]
    # def clone
    #   copied = super
    #   val = (@sep.clone        rescue @sep)  # rescue in case of immutable.
    #   copied.instance_eval{ @sep = val }
    #   copied 
    # end
 
    # Equal operator
    #
    # Unless both are kind of Part instances, false is returned.
    # If you want to make comparison in the Array level, do
    #   p1.to_a == a1.to_a
    #
    # @param other [Object]
    def ==(other)
      return false if !other.class.method_defined?(:to_ary)
      %i(parts boundaries).each do |ea_m|  # %i(...) defined in Ruby 2.0 and later
        return false if !other.class.method_defined?(ea_m) || (self.public_send(ea_m) != other.public_send(ea_m))  # public_send() defined in Ruby 2.0 (1.9?) and later
      end
      super
    end
 

    # # Multiplication operator
    # #
    # # @param other [Integer, String]
    # # @return as self
    # def *(other)
    #   super
    # end


    # Plus operator
    #
    # @param other [Object]
    # @return as self
    def +(other)
      # ## The following is strict, but a bit redundant.
      # # is_part = true  # Whether "other" is a Part class instance.
      # # %i(to_ary parts boundaries).each do |ea_m|  # %i(...) defined in Ruby 2.0 and later
      # #   is_part &&= other.class.method_defined?(ea_m)
      # # end

      # begin
      #   other_even_odd = 
      #     ([other.parts, other.boundaries] rescue even_odd_arrays(self, size_even: true, filler: ""))
      # rescue NoMethodError
      #   raise TypeError, sprintf("no implicit conversion of %s into %s", other.class.name, self.class.name)
      # end

      # # eg., if self is PlainText::Part::Section, the returned object is the same.
      # ret = self.class.new(self.parts+other_even_odd[0], self.boundaries+other_even_odd[1])
      ret = self.class.new super
      ret.normalize!
    end
 

    # Minus operator
    #
    # @param other [Object]
    # @return as self
    def -(other)
      ret = self.class.new super
      ret.normalize!
    end
 
    # Array#<< is now undefined
    # (because the instances of this class must take always an even number of elements).
    undef_method(:<<) if method_defined?(:<<)
 
    # Array#delete_at is now undefined
    # (because the instances of this class must have always an even number of elements).
    undef_method(:delete_at) if method_defined?(:delete_at)

    # Returns a partial Part-Array (or Object, if a single Integer is specified)
    #
    # Because the returned object is this class of instance (when a pair of Integer or Range
    # is specified), only an even number of elements, starting from an even number of index,
    # is allowed.
    #
    # @param arg1 [Integer, Range]
    # @option arg2 [Integer, NilClass]
    # @return [Object]
    def [](arg1, *rest)
      arg2 = rest[0]
      return super(arg1) if !arg2 && !arg1.class.method_defined?(:exclude_end?)

      check_bracket_args_type_error(arg1, arg2)  # Args are now either (Int, Int) or (Range)

      if arg2
        size2ret = size2extract(arg1, arg2, ignore_error: true)  # maybe nil (if the index is too small).
        raise ArgumentError, ERR_MSGS[:even_num]+" "+ERR_MSGS[:use_to_a] if size2ret.odd?
        begin
          raise ArgumentError, "odd index is not allowed as the starting index for #{self.class.name}.  It must be even. "+ERR_MSGS[:use_to_a] if positive_array_index_checked(arg1, self).odd?
        rescue TypeError, IndexError
          # handled by super
        end
        return super
      end

      begin
        rang = normalize_index_range(arg1)
      rescue IndexError #=> err
        return nil
        # raise RangeError, err.message
      end

      raise RangeError if rang.begin < 0 || rang.end < 0

      # The end is smaller than the begin in the positive index.  Empty instance of this class is returned.
      if rang.end < rang.begin
        return super
      end

      raise RangeError, "odd index is not allowed as the starting Range for #{sefl.class.name}.  It must be even. "+ERR_MSGS[:use_to_a] if rang.begin.odd?
      size2ret = size2extract(rang, skip_renormalize: true)
      raise ArgumentError, ERR_MSGS[:even_num]+" "+ERR_MSGS[:use_to_a] if size2ret.odd?
      super
    end
 

    # Replaces some of the Array content.
    #
    # @param arg1 [Integer, Range]
    # @option arg2 [Integer, NilClass]
    # @return [Object]
    def []=(arg1, *rest)
      if rest.size == 1
        arg2, val = [nil, rest[-1]]
      else
        arg2, val = rest
      end

      # Simple substitution to a single element
      return super(arg1, val) if !arg2 && !arg1.class.method_defined?(:exclude_end?)

      check_bracket_args_type_error(arg1, arg2)  # Args are now either (Int, Int) or (Range)

      # raise TypeError, "object to replace must be Array type with an even number of elements." if !val.class.method_defined?(:to_ary) || val.size.odd?

      vals = (val.to_ary rescue [val])
      if arg2
        size2delete = size2extract(arg1, arg2, ignore_error: true)  # maybe nil (if the index is too small).
        raise ArgumentError, "odd-even parity of size of array to replace must be identical to that to slice." if size2delete && ((size2delete % 2) != (vals.size % 2))
        return super
      end

      begin
        rang = normalize_index_range(arg1)
      rescue IndexError => err
        raise RangeError, err.message
      end

      raise RangeError if rang.begin < 0 || rang.end < 0

      # The end is smaller than the begin in the positive index.  It is the same as insert (default in Ruby), except it returns the replaced Object (which may not be an Array).
      if rang.end < rang.begin
        insert(arg1, *vals)
        return val
      end

      size2delete = size2extract(rang, skip_renormalize: true)
      raise ArgumentError, "odd-even parity of size of array to replace must be identical to that to slice." if size2delete && ((size2delete % 2) != (vals.size % 2))
      ret = super

      # The result may not be in an even number anymore.  Correct it.
      push Boundary.new("") if size.odd?

      # Original method may fill some part of the array with String or even nil.  
      normalize!
      ret
    end

    # Array#insert
    #
    # The most basic method to add/insert elements to self.  Called from {#[]=} and {#push}, for example.
    #
    # If ind is greater than size, a number of "", as opposed to nil, are inserted.
    #
    # @param ind [Index]
    # @param rest [Array] This must have an even number of arguments, unless ind is larger than the array size and an odd number.
    # @option primitive: [String] if true (Def: false), the original {#insert_original_b4_part} is called.
    # @return [self]
    def insert(ind, *rest, primitive: false)
      return insert_original_b4_part(ind, *rest) if primitive
      ipos = positive_array_index_checked(ind, self)
      if    rest.size.even? && (ipos > size - 1) && ipos.even?  # ipos.even? is equivalent to index_para?(ipos), i.e., "is the index for Paragraph?"
        raise ArgumentError, sprintf("number of arguments (%d) must be odd for index %s.", rest.size, ind)
      elsif rest.size.odd?  && (ipos <= size - 1)
        raise ArgumentError, sprintf("number of arguments (%d) must be even.", rest.size)
      end

      if ipos >= size
        rest = Array.new(ipos - size).map{|i| ""} + rest
        ipos = size
      end

      super(ipos, rest)
    end


    # Delete elements and return the deleted content or nil if nothing is deleted.
    #
    # The number of elements to be deleted must be even.
    #
    # @param arg1 [Integer, Range]
    # @option arg2 [Integer, NilClass]
    # @option primitive: [Boolean] if true (Def: false), the original {#insert_original_b4_part} is called.
    # @return as self or NilClass
    def slice!(arg1, *rest, primitive: false)
      return slice_original_b4_part!(arg1, *rest) if primitive

      arg2 = rest[0]

      # Simple substitution to a single element
      raise ArgumentError, ERR_MSGS[:even_num] if !arg2 && !arg1.class.method_defined?(:exclude_end?)

      check_bracket_args_type_error(arg1, arg2)  # Args are now either (Int, Int) or (Range)

      if arg2
        size2delete = size2extract(arg1, arg2, ignore_error: true)  # maybe nil (if the index is too small).
        # raise ArgumentError, ERR_MSGS[:even_num] if arg2.to_int.odd?
        raise ArgumentError, ERR_MSGS[:even_num] if size2delete && size2delete.odd?
        raise ArgumentError, "odd index is not allowed as the starting Range for #{self.class.name}.  It must be even." if arg1.odd?  # Because the returned value is this class of instance.
        return super(arg1, *rest)
      end

      begin
        rang = normalize_index_range(arg1)
      rescue IndexError => err
        raise RangeError, err.message
      end

      raise RangeError if rang.begin < 0 || rang.end < 0

      return super(arg1, *rest) if (rang.begin > rang.end)  # nil or [] is returned

      size2delete = size2extract(rang, skip_renormalize: true)
      raise ArgumentError, ERR_MSGS[:even_num] if size2delete && size2delete.odd? 
      raise ArgumentError, "odd index is not allowed as the starting Range for #{self.class.name}.  It must be even." if rang.begin.odd?  # Because the returned value is this class of instance.
      super(arg1, *rest)
    end
 
 
    ########## Other methods of Array ##########

    # Array#compact!
    #
    # If changed, re-{#normalize!} it.
    #
    # @return [self, NilClass]
    def compact!
      ret = super
      ret ? ret.normalize!(recursive: false) : ret
    end

    # Array#concat
    #
    # @see #insert
    #
    # @param *rest [Array<Array>]
    # @return [self]
    def concat(*rest)
      insert(size, *(rest.sum([])))
    end

    # Array#push
    #
    # @see #concat
    #
    # @param ary [Array]
    # @return [self]
    def push(*rest)
      concat(rest)
    end

    # {#append} is an alias to {#push}
    alias :append :push

    # {#slice} is an alias to {#[]}
    alias :slice :[]

 
    ##########
    # Private instance methods
    ##########

    private

    # Checking whether index-type arguments conform
    #
    # After this, it is guaranteed the arguments are either (Integer, Integer) or (Range, nil).
    #
    # @param arg1 [Integer, Range] Starting index or Range.  Maybe including negative values.
    # @option arg2 [Integer, NilClass] Size.
    # @return [NilClass]
    # @raise [TypeError] if not conforms.
    def check_bracket_args_type_error(arg1, arg2=nil)
      if arg2
        raise TypeError, sprintf("no implicit conversion of #{arg2.class} into Integer") if !arg2.class.method_defined?(:to_int)
      else
        raise TypeError if !arg1.class.method_defined?(:exclude_end?)
      end
    end
    private :check_bracket_args_type_error
 
 
    # Emptifies all the Boundaries immediately before the index and squashes it to the one at it.
    #
    # @return [Boundary] all the descendants' last Boundaries merged.
    def emptify_last_boundaries!
      return Boundary::Empty.dup if size == 0
      ret = ""
      ret << prt.public_send(__method__) if prt.class.method_defined? __method__
      ret << self[-1]
      self[-1] = Boundary::Empty.dup
      ret
    end
    private :emptify_last_boundaries!


    # Returns a positive Integer index guaranteed to be 1 or greater and smaller than the size.
    #
    # @param index [Integer]
    # @return [Integer, nil] nil if a too large index is specified.
    def get_valid_ipos_for_boundary(index)
      i_pos = positive_array_index_checked(index, self)
      raise ArgumentError, "Index #{index} specified was for Part/Paragraph, which should be for Boundary." if index_para?(i_pos, skip_check: true)
      (i_pos > size - 1) ? nil : i_pos
    end
    private :get_valid_ipos_for_boundary


    # Core routine for {#map_boundaries} and similar.
    #
    # @option map opts: [Boolean] if true (Default), map is performed. Else just each.
    # @option with_index: [Boolean] if true (Default: false), yield with also index
    # @option recursive: [Boolean] if true (Default), map is performed recursively.
    # @return as self if map: is true, else void
    def map_boundaries_core(map: true, with_index: false, recursive: true, **kwd, &bl)
      ind = -1
      arnew = map{ |ec|
        ind += 1
        if recursive && index_para?(ind, skip_check: true) && ec.class.method_defined?(__method__)
          ec.public_send(__method__, recursive: true, **kwd, &bl)
        elsif !index_para?(ind, skip_check: true)
          with_index ? yield(ec, ind) : yield(ec)
        else
          ec
        end
      }
      self.class.new arnew, recursive: recursive, **kwd if map
    end
    private :map_boundaries_core

    # Core routine for {#map_parts}
    #
    # @option map: [Boolean] if true (Default), map is performed. Else just each.
    # @option with_index: [Boolean] if true (Default: false), yield with also index
    # @option recursive: [Boolean] if true (Default), map is performed recursively.
    # @return as self
    # @see #initialize for the other options (:compact and :compacter)
    def map_parts_core(map: true, with_index: false, recursive: true, **kwd, &bl)
      ind = -1
      new_parts = parts.map{ |ec|
        ind += 1
        if recursive && ec.class.method_defined?(__method__)
          ec.public_send(__method__, recursive: true, **kwd, &bl)
        else
          with_index ? yield(ec, ind) : yield(ec)
        end
      }
      self.class.new new_parts, boundaries, recursive: recursive, **kwd if map
    end
    private :map_parts_core

    # Core routine for {#normalize!} and {#normalize}
    #
    # @param ea [Array, String, NilClass] the element to evaluate
    # @param i [Integer] Main array index
    # @option recursive: [Boolean] if true (Default), normalize recursively.
    # @option ignore_array_boundary: [Boolean] if true (Default), even if a Boundary element (odd-numbered index) is an Array, ignore it.
    # @return [Part, Paragraph, Boundary]
    def normalize_core(ea, i, recursive: true, ignore_array_boundary: true)
      if    ea.class.method_defined?(:to_ary)
        if index_para?(i, skip_check: true) || ignore_array_boundary
          (/\APlainText::/ =~ ea.class.name && defined?(ea.normalize)) ? (recursive ? ea.normalize : ea) : self.class.new(ea, recursive: recursive)
        else
          raise "Index ({#i}) is an Array or its child, but it should be Boundary or String."
        end
      elsif ea.class.method_defined?(:to_str)
        if /\APlainText::/ =~ ea.class.name
          # Paragraph or Boundary
          ea.unicode_normalize
        else
          if index_para?(i, skip_check: true)
            Paragraph.new(ea.unicode_normalize || "")
          else
            Boundary.new( ea.unicode_normalize || "")
          end
        end
      else
        raise ArgumentError, "Unrecognised elements for #{self.class}: "+ea.inspect
      end
    end
    private :normalize_core


    # Returns (inclusive, i.e., not "...") Range of non-negative indices
    #
    # @param rng [Range] It has to be a Range
    # @return [Range]
    # @raise [IndexError] if too negative index is specified.
    def normalize_index_range(rng, **kwd)
      # NOTE to developers: (0..-1).to_a returns [] (!)
      arpair = [rng.begin, rng.end].to_a.map{ |i| positive_array_index_checked(i, self, **kwd) }
      arpair[1] -= 1 if rng.exclude_end?
      (arpair[0]..arpair[1])
    end
    private :normalize_index_range
 
 
    # Returns the size (the number of elements) to extract
    #
    # taking into account the size of self
    #
    # 1. if (3, 2) is specified when self.size==4, this returns 1.
    # 2. if (3..2) is specified, this returns 0.
    #
    # Make sure to call {#check_bracket_args_type_error} beforehand.
    #
    # @param arg1 [Integer, Range] Starting index or Range.  Maybe including negative values.
    # @option arg2 [Integer, NilClass] Size.
    # @option ignore_error: [Boolean] if true (Def: false), nil is returned instead of raising IndexError (when a negative index is too small)
    # @option skip_renormalize: [Boolean] if true (Def: false), the given Range is assumed to be already normalized by {#normalize_index_range}
    # @return [Integer, NilClass] nil if an Error is raised with ignore_error being true
    def size2extract(arg1, arg2=nil, ignore_error: false, skip_renormalize: false, **kwd)
      begin
        if arg1.class.method_defined? :exclude_end?
          rng = arg1
          rng = normalize_index_range(rng, **kwd) if !skip_renormalize
        else
          ipos = positive_array_index_checked(arg1, self)
          rng = (ipos..(ipos+arg2.to_int-1))
        end
        return 0 if rng.begin > size-1
        return 0 if rng.begin > rng.end
        return [rng.end, size-1].min-rng.begin+1
      rescue IndexError
        return nil if ignore_error
        raise
      end
    end
    private :size2extract

  end # class Part < Array

end # module PlainText


####################################################
# Modifies Array
####################################################

class Array

  # Original equal and plus operators of Array
  hsmethod = {
    :equal_original_b4_part? => :== ,
    # :plus_operator_original_b4_part => :+
  }

  hsmethod.each_pair do |k, ea_orig|
    if self.method_defined?(k)
      # To Developer: If you see this message, switch the DEBUG flag on (-d option) and run it.
      warn sprintf("WARNING: Method %s#%s has been already defined, which should not be.  Contact the code developer. Line %d in %s%s", self.name, k.to_s, __FILE__, __LINE__, ($DEBUG ? "\n"+caller_locations.join("\n").map{|i| "  "+i} : ""))
    else
      alias_method k, ea_orig
    end
  end

  # Equal operator modified to deal with {PlainText::Part}
  #
  # @param other [Object]
  def ==(other)
    return false if !other.class.method_defined?(:to_ary)
    %i(parts boundaries).each do |ea_m|  # %i(...) defined in Ruby 2.0 and later
      return equal_original_b4_part?(other) if !other.class.method_defined?(ea_m)
      return false if !self.class.method_defined?(ea_m) || (self.public_send(ea_m) != other.public_send(ea_m))  # public_send() defined in Ruby 2.0 (1.9?) and later
    end
    true
  end

end

####################################################
# require (after the module is defined)
####################################################

require 'plain_text/part/paragraph'
require 'plain_text/part/boundary'
require "plain_text/parse_rule"

#######
# idea
#   * Potentially, a specification of the main array of always an odd number of elements is possible: [Para, Boundary, B, P, B, P], either or both of the last and first of which may be empty.
#   * then joining is very straightforward.
#   * A trouble is, open/close tab structures like HTML/LaTeX-type (+<ul>...</ul>+) are not represented very well.
#
