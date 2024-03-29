# -*- coding: utf-8 -*-

require_relative "error"
require_relative "builtin_type"
require_relative "util"

module PlainText

  # Class to represent a Chapter-like entity, which behaves like an Array
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
  #     (0) Part::Paragraph::Empty,
  #     (1) Part::Boundary::General,
  #     (2) Part::ArticleHeader(
  #           (0) Part::Paragraph::Title,
  #           (1) Part::Boundary::Empty
  #         ),
  #     (3) Part::Boundary::TitleMain,
  #     (4) Part::ArticleMain(
  #           (0) Part::ArticleSection(
  #                 (0) Part::Paragraph::Title,
  #                 (1) Part::Boundary::General,
  #                 (2) Part::Paragraph::General,
  #                 (3) Part::Boundary::General,
  #                 (4) Part::ArticleSubSection(...),
  #                 (5) Part::Boundary::General,
  #                 (6) Part::Paragraph::General,
  #                 (7) Part::Boundary::Empty
  #               ),
  #           (1) Part::Boundary::General,
  #           (2) Part::Paragraph::General,
  #           (3) Part::Boundary::Empty
  #         ),
  #     (5) Part::Boundary::General
  #   )
  #
  # A Section (Part) always has an even number of elements: pairs of a Para ({Part}|{Paragraph}) and {Boundary} in this order.
  #
  # This class behaves like an Array and so Array methods that usually return
  # an Array returns an instance of this class, such as +pt[0..-2]+.
  # However, not all Array methods are accepted in the same way.
  # For example, for the instance +pt+, +pt[0..-2]+ raises an Exception
  # because it would violate the principle of the instance of this class
  # having always an even number of elements.  Use +to_a+ to obtain
  # a standard Array; e.g., +pt.to_a[0..-2]+ returns an Array with
  # an odd number of elements.
  #
  # Some destructive Array operations, most notably +#delete+, +#delete_if+, +#reject!+,
  # +#select!+, +#filter!+, +#keep_if+, +#flatten!+, +#uniq!+ may alter the content in a way
  # it breaks the self-consistency of the object.
  # Use it at your own risk, if you wish (or don't).
  # Such operations may become prohibited in the future release.
  # {#<<} and {#delete_at} are currently disabled.
  #
  # An instance of this class is always *non-equal* to that of the standard Array class.
  # To compare it at the Array level, convert a {Part} class instance into Array
  # with {#to_a} first: +pt.to_a == my_array+
  #
  # For CRUD of elements (contents) of an instance, the following methods are most basic:
  #
  # * Create:
  #   * Use +PlainText::Part.new+ (see {PlainText::Part.initialize})
  # * Read:
  #   * All non-destructive Array operations are permitted and returns an instance of this class if the corresponding Array method returns an Array, providing it does not break the self-consistency.
  #   * {#to_a} gives or exposes the internal Array object, and then you can do whatever manipulation allowed for Array with it, if you insist.  Note that destructive modification of the object carries a risk of breaking self-consistency of the instance and so is highly discouraged.  You must know what you are doing if you do.
  # * Update:
  #   * Insert/Append: {#insert} to insert. If the specified index is #size}, it means "append". For primitive operations, specify +primitive: true+ to skip various checks performed to guarantee the self-consistency as an instance of this class.
  #   * Replace: {#[]=} has some restrictions, such as, if multiple elements are replaced, they have to be pairs of Paragraph and Boundary.  To skip all the checks, do {#insert} with +primitive: true+
  # * Delete:
  #   * Delete: {#slice!} to delete. For primitive operations, specify +primitive: true+ to skip various checks performed to guarantee the self-consistency as an instance of this class.
  #     * +#delete_at+ is disabled. +#delete+, +#delete_if+, +#reject!+, +#select!+, +#filter!+, +#keep_if+ (and +#drop_while+ and +#take_whie+ in recent Ruby) remain enabled, but if you use them, do so at your own risk, as no self-consistency checks would be performed automatically. {#normalize} would return the self-consistent instance, or its destructive version, {#normalize!}.
  #
  # @author Masa Sakano (Wise Babel Ltd)
  #
  # @todo methods
  #   * flatten
  #
  class Part

    include PlainText::BuiltinType
    include PlainText::Util

    # Array methods that are disabled for this class.
    DISABLED_ARRAY_METHODS = %i(<< delete_at)

    # Error messages
    ERR_MSGS = {
      even_num: 'even number of elements must be specified.',
      use_to_a: 'To handle it as an Array, use to_a first.',
    }
    private_constant :ERR_MSGS

    # Constructor
    #
    # New String-type objects are always created, i.e.,
    # regardless of whether the input is a pure String or {Paragraph} etc,
    # a new {Paragraph} is always created from {Paragraph#to_s}. Therefore,
    # even if one of the String given to the argument is destructively
    # modified, it does not affect the generated {Part} object. This also means
    # that if the input {Paragraph} has special singloton methods or
    # instance variables, the information will be lost.
    #
    # @param arin [Array] of [Paragraph1, Boundary1, Para2, Bd2, ...] or just of Paragraphs if boundaries is given as the second arguments
    # @param boundaries [Array] of Boundary
    # @option recursive: [Boolean] if true (Default), normalize recursively.
    # @option compact: [Boolean] if true (Default), pairs of nil paragraph and boundary are removed.  Otherwise, nil is converted to an empty string.
    # @option compacter: [Boolean] if true (Default), pairs of nil or empty paragraph and boundary are removed.
    # @return [self]
    def initialize(arin, boundaries=nil, recursive: true, compact: true, compacter: true)
      raise ArgumentError, "Arguments must be an Array(s) or equivalent: "+arin.inspect+(boundaries ? ", "+boundaries.inspect : "") if (!arin.respond_to?(:compact) && !arin.respond_to?(:paras)) || boundaries && !boundaries.respond_to?(:compact)  # arin must be an Array or Part
      if !boundaries
        @array = arin.clone
        #super(arin)
      else
        raise ArgumentError, "Two main Arrays must have the same size." if arin.size != boundaries.size

        armain = []
        arin.each_with_index do |ea_e, i|
          armain << ea_e
          armain << (boundaries[i] || Boundary.new(''))
        end
        @array = armain
        #super armain
      end

      begin
        normalize!(recursive: recursive, compact: compact, compacter: compacter)
      rescue PlainText::PartNormalizeError => err
        raise TypeError, err.message
      end
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

    # Returns true if it is {PlainText::Part}
    def self.part?(other)
      _part_paragraph_boundary?(other, __method__)
    end

    # Returns true if it is {PlainText::Part::Boundary}
    def self.boundary?(other)
      _part_paragraph_boundary?(other, __method__)
    end

    # Returns true if it is {PlainText::Part::Paragraph}
    def self.paragraph?(other)
      _part_paragraph_boundary?(other, __method__)
    end

    # Returns true if it is built-in String or similar
    def self.builtin_string?(other)
      other.respond_to?(:to_str) && !boundary? && !paragraph?
    end

    # Core routines for {Part.part?} etc.
    def self._part_paragraph_boundary?(other, metho)
      %i(boundary? paragraph? part?).all?{|i| other.respond_to? i} && other.send(metho)
    end
    private_class_method :_part_paragraph_boundary?


    ####################################################
    # Instance methods
    ####################################################

    ##########
    # Unique instance methods (not existing in Array)
    ##########

    def boundary?
      false
    end

    def paragraph?
      false
    end

    def part?
      true
    end

    # Returns an array of boundaries (odd-number-index elements), consisting of Boundaries
    #
    # @return [Array<Boundary>]
    # @see #paras
    def boundaries
      @array.select.with_index { |_, i| i.odd? } rescue @array.select.each_with_index { |_, i| i.odd? } # Rescue for Ruby 2.1 or earlier
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
      prt = @array[i_pos-1]
      arret = prt.public_send(__method__, -1) if prt.respond_to? __method__
      arret << @array[index]
    end

    # Returns a dup-ped instance with all the Arrays and Strings dup-ped.
    #
    # @return [Part]
    def deepcopy
      _return_this_or_other{
        @array.dup.map!{ |i| i.respond_to?(:deepcopy) ? i.deepcopy : (i.dup rescue i)}
        # the "rescue" deals with cases where i is immutable (which should never happen and in fact it would not raise an Exception in Ruby 3 seemingly).
      }
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
    # @param (see #map_boundary_with_index)
    # @return as self
    def each_boundary_with_index(**kwd, &bl)
      map_boundary_core(do_map: false, with_index: true, **kwd, &bl)
    end

    # each method for Paras only, providing also the index (always an even number) to the block.
    #
    # For just looping over the elements of {#paras}, do simply
    #
    #   paras.each do |ec|
    #   end
    #
    # The indices provided in this method are for the main Array,
    # and hence different from {#paras}.each_with_index
    #
    # @param (see #map_para_with_index)
    # @return as self
    def each_para_with_index(**kwd, &bl)
      map_para_core(do_map: false, with_index: false, **kwd, &bl)
    end

    # The first significant (=non-empty) element.
    #
    # If the returned value is non-nil and destructively altered, self changes.
    #
    # @return [Integer, nil] if self.empty? nil is returned.
    def first_significant_element
      (i = first_significant_index) || return
      @array[i]
    end

    # Index of the first significant (=non-empty) element.
    #
    # If every element is empty, the last index is returned.
    #
    # @return [Integer, nil] if self.empty? nil is returned.
    def first_significant_index
      return nil if @array.empty?
      @array.find_index do |val|
        val && !val.empty?
      end || (@array.size-1)
    end

    # True if the index should be semantically for Paragraph?
    #
    # @param i [Integer] index for the array of self
    # @option accept_negative: [Boolean] if false (Default: true), skip conversion of the negative index to positive.
    # @see #paras
    def index_para?(i, accept_negative: true)
      accept_negative ? positive_array_index_checked(i, @array).even? : i.even?
    end

    # The last significant (=non-empty) element.
    #
    # If the returned value is non-nil and destructively altered, self changes.
    #
    # @return [Integer, nil] if self.empty? nil is returned.
    def last_significant_element
      (i = last_significant_index) || return
      @array[i]
    end

    # Index of the last significant (=non-empty) element.
    #
    # If every element is empty, 0 is returned.
    #
    # @return [Integer, nil] if self.empty? nil is returned.
    def last_significant_index
      return nil if empty?
      (0..(size-1)).to_a.reverse.each do |i|
        return i if @array[i] && !@array[i].empty?  # self for sanity
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
    def map_boundary(**kwd, &bl)
      map_boundary_core(with_index: false, **kwd, &bl)
    end

    # map method for boundaries only, providing also the index (always an odd number) to the block, returning a copied self.
    #
    # @param (see #map_boundary)
    # @return as self
    def map_boundary_with_index(**kwd, &bl)
      map_boundary_core(with_index: true, **kwd, &bl)
    end

    # map method for Paras only, returning a copied self.
    #
    # If recursive is true (Default), any Paras in the descendant Parts are also handled.
    #
    # If a Paragraph is set nil or empty, along with the following Boundary,
    # the pair is removed from the returned instance in Default (:compact and :compacter options
    # - see {#initialize} for detail)
    #
    # @option recursive: [Boolean] if true (Default), map is performed recursively.
    # @return as self
    # @see #initialize for the other options (:compact and :compacter)
    def map_para(**kwd, &bl)
      map_para_core(with_index: false, **kwd, &bl)
    end

    # map method for paras only, providing also the index (always an even number) to the block, returning a copied self.
    #
    # @param (see #map_para)
    # @return as self
    def map_para_with_index(**kwd, &bl)
      map_para_core(with_index: false, **kwd, &bl)
    end

    # merge Paras if they satisfy the conditions.
    #
    # A group of two Paras and the Boundaries in between and before and after
    # is passed to the block consecutively.
    #
    # @yield [ary, b1, b2, i] Returns true if the two paragraphs should be merged.
    # @yieldparam [Array] ary of [Para1st, BoundaryBetween, Para2nd]
    # @yieldparam [Boundary] b1 Boundary-String before the first Para (nil for the first one)
    # @yieldparam [Boundary] b2 Boundary-String after the second Para
    # @yieldparam [Integer] i Index of the first Para
    # @yieldreturn [Boolean, Symbol] True if they should be merged.  :abort if cancel it.
    # @return [self, false] false if no pairs of Paras are merged, else self.
    def merge_para_if()
      arind2del = []  # Indices to delete (both paras and boundaries)
      @array.each_index do |ei|
        break if ei >= @array.size - 3  # 2nd last paragraph or later.
        next if !index_para?(ei, accept_negative: false)
        ar1st = @array[ei..ei+2]
        ar2nd = ((ei==0) ? nil : @array[ei-1])
        do_merge = yield(ar1st, ar2nd, @array[ei+3], ei)
        return false                 if do_merge == :abort
        arind2del.push ei, ei+1, ei+2 if do_merge 
      end

      return false if arind2del.empty? 
      arind2del.uniq!

      (arind2ranges arind2del).reverse.each do |er|
        merge_para!(er)
      end
      return self
    end

    # merge multiple paragraphs
    #
    # The boundaries between them are simply joined as String as they are.
    #
    # @overload set(index1, index2, *rest)
    #   With a list of indices.  Unless use_para_index is true, this means the main Array index. Namely, if Part is [P0, B0, P1, B1, P2, B2, B3] and if you want to merge P1 and P2, you specify as (2,3,4) or (2,4).  If use_para_index is true, specify as (1,2).
    #   @param index1 [Integer] the first index to merge
    #   @param index2 [Integer] the second index to merge, and so on...
    # @overload set(range)
    #   With a range of the indices to merge. Unless use_para_index is true, this means the main Array index. See the first overload set about it.
    #   @param range [Range] describe value param
    # @param use_para_index [Boolean] If false (Default), the indices are for the main indices (alternative between Paras and Boundaries, starting from Para). If true, the indices are as obtained with {#paras}, namely the array containing only Paras.
    # @return [self, nil] nil if nothing is merged (because of wrong indices).
    def merge_para!(*rest, use_para_index: false)
$myd = true
      (ranchk = build_index_range_for_merge_para!(*rest, use_para_index: use_para_index)) || (return self)  # Do nothing.
      # ranchk is guaranteed to have a size of 2 or greater.
      @array[ranchk] = [Paragraph.new(@array[ranchk][0..-2].join), @array[ranchk.end]]  # Array[Range] replaced with 2-elements (Para, Boundary)
      self
    end

    # Building a proper array for the indices to merge
    #
    # Returns always an even number of Range, starting from para,
    # like (2..5), the last of which is a Boundary which is not merged.
    # In this example, Para(i=2)/Boundary(3)/Para(4) is merged,
    # while Boundary(5) stays as it is.
    #
    # @param (see #merge_para!)
    # @param use_para_index [Boolean] false
    # @return [Range, nil] nil if no range is selected.
    def build_index_range_for_merge_para!(*rest, use_para_index: false)
      inary = rest.flatten
      return nil if inary.empty?
      # inary = inary[0] if like_range?(inary[0])
      (ary = to_ary_positive_index(inary, @array)) || return  # Guaranteed to be an array of positive indices (sorted and uniq-ed).
      return nil if ary.empty?

      # Normalize so the array contains both Paragraph and Boundaries in between.
      # After this, ary must be [Para1-index, Boundary1-index, P2, B2, ..., Pn-index, Bn-index]
      # Note: In the input, the index is probably for Paragraph.  But,
      #   for the sake of later processing, make the array contain an even number
      #   of elements, ending with Boundary.
      if use_para_index
        ary = ary.map{|i| [i*2, i*2+1]}.flatten
      elsif index_para?(ary[-1], accept_negative: false)
        # The last index in the given Array or Range was for Paragraph (Likely case).
        ary.push(ary[-1]+1)
      end

      # Exception if they are not consecutive.
      ary.inject{|memo, val| (val == memo+1) ? val : raise(ArgumentError, "Given (Paragraph) indices are not consecutive.")}

$myd = false
      # Exception if the first index is for Boundary and no Paragraph.
      raise ArgumentError, "The first index (#{ary[0]}) is not for Paragraph." if !index_para?(ary[0], accept_negative: false)

      i_end = [ary[-1], size-1].min
      return if i_end - ary[0] < 3  # No more than 1 para selected.

      (ary[0]..ary[-1])
    end
    private :build_index_range_for_merge_para!

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
      size_parity = (@array.size.even? ? 0 : 1)
      if (@array.compact || compacter) && (@array.size > 0+size_parity)
        ((@array.size-2-size_parity)..0).each do |i| 
          # Loop over every Paragraph
          next if i.odd?
          @array.slice! i, 2 if @array.compact &&  !@array[i] && !@array[i+1]
          @array.slice! i, 2 if compacter      && (!@array[i] || @array[i].empty?) && (!@array[i+1] || @array[i+1].empty?)
        end
      end

      @array.map!.with_index{ |ea, ind|
        ax = normalize_core(ea, ind, recursive: recursive)
        ax
        #normalize_core(ea, ind, recursive: recursive)
      }
      @array.insert(@array.size, Boundary.new('')) if @array.size.odd?
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
      arall = @array
      size_parity = (@array.size.even? ? 0 : 1)
      if (@array.compact || compacter) && (@array.size > 0+size_parity)
        ((@array.size-2-size_parity)..0).each do |i| 
          # Loop over every Paragraph
          next if i.odd?
          arall.slice! i, 2 if compact   &&  !@array[i] && !@array[i+1]
          arall.slice! i, 2 if compacter && (!@array[i] || @array[i].empty?) && (!@array[i+1] || @array[i+1].empty?)
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


    # Returns an array of Paras (even-number-index elements), consisting of Part and/or Paragraph
    #
    # @return [Array<Part, Paragraph>]
    # @see #boundaries
    def paras
      @array.select.with_index { |_, i| i.even? } rescue @array.select.each_with_index { |_, i| i.even? } # Rescue for Ruby 2.1 or earlier
      # ret.freeze
    end

    # Reparses self or a part of it.
    #
    # @option rule [PlainText::ParseRule] (PlainText::ParseRule::RuleConsecutiveLbs)
    # @option name [String, Symbol, Integer, nil] Identifier of rule, if need to specify.
    # @option range [Range, nil] Range of indices of self to reparse. In Default, the entire self.
    # @return [self]
    def reparse!(rule: PlainText::ParseRule::RuleConsecutiveLbs, name: nil, range: (0..-1))
      insert range.begin, self.class.parse((range ? @array[range] : self), rule: rule, name: name)
      self
    end

    # Non-destructive version of {reparse!}
    #
    # @param (see #reparse!)
    # @return [PlainText::Part]
    def reparse(**kwd)
      ret = @array.dup
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
      prt = @array[i_pos-1]
      m = :emptify_last_boundary!
      @array[i_pos] << prt.public_send(m) if prt.respond_to? m
      @array[i_pos]
    end


    # Wrapper of {#squash_boundary_at!} to loop over the whole {Part}
    #
    # @return [self]
    def squash_boundaries!
      each_boundary_with_index do |ec, i|
        squash_boundary_at!(i)
      end
      self
    end


    ##########
    # Overwriting instance methods of the parent Object or Array class
    ##########

    ########## Most basic methods (Object/BasicObject) ##########

    # @return [String]
    def inspect
      self.class.name + @array.inspect
    end

    # @return [Array]
    def to_a
      @array
    end
    alias_method :to_ary, :to_a
    alias_method :instance, :to_a  if ! self.method_defined?(:instance)

    # Work around because Object#dup does not dup the instance variable @array
    #
    # @return [PlainText::Part]
    def dup
      dup_or_clone(super, __method__, '@array') # defined in builtin_type.rb
    end

    # Work around because Object#clone does not clone the instance variable @array
    #
    # @return [PlainText::Part]
    def clone
      dup_or_clone(super, __method__, '@array') # defined in builtin_type.rb
    end
 
    # Equal operator
    #
    # Unless both are kind of Part instances, false is returned.
    # If you want to make comparison in the Array level, do
    #   p1.to_a == a1.to_a
    #
    # @param other [Object]
    def ==(other)
      return false if  !other.respond_to?(:to_ary) || !other.respond_to?(:normalize!)
      %i(paras boundaries).each do |ea_m|  # %i(...) defined in Ruby 2.0 and later
        return false if !other.respond_to?(ea_m) || (self.public_send(ea_m) != other.public_send(ea_m))  # public_send() defined in Ruby 2.0 (1.9?) and later
      end
      @array == other.to_a  # or you may just return true?
    end
 

    # Plus operator
    #
    # @param other [Object]
    # @return as self
    def +(other)
      # # eg., if self is PlainText::Part::Section, the returned object is the same.
      # ret = self.class.new(self.paras+other_even_odd[0], self.boundaries+other_even_odd[1])
      raise(TypeError, "cannot operate with no #{self.class.name} instance (#{other.class.name})") if (!other.respond_to?(:to_ary) && !other.respond_to?(:normalize!))
      ret = self.class.new(@array+other.to_ary)
      ret.normalize!
    end
 

    # Minus operator
    #
    # @param other [Object]
    # @return as self
    def -(other)
      raise ArgumentError, "cannot operate with no {self.class.name} instance" if !other.respond_to?(:to_ary) || !other.respond_to?(:normalize!)
      ret = self.class.new(@array+other.to_ary)
      ret.normalize!
    end
 
    # if the Array method returns an Array, returns this class instance.
    #
    # Note that even the value is this-class instance, a new instance is created
    # in default unless it is +eql?(self)+.
    #
    # @param obj [Object] the value to be evaluated.
    # @return [Object]
    # @yield [] the returned value is evaluated, if no argument is given
    # @yieldreturn [Object] Either this-class instance or Object
    def _return_this_or_other(obj=nil)
      ret = (block_given? ? yield : obj)
      (ret.respond_to?(:to_ary) && !ret.eql?(self)) ? self.class.new(ret) : ret
    end
    private :_return_this_or_other
 
    # Basically delegates everything to Array
    #
    # Array#<< and Array#delete_at are undefined
    # because the instances of this class must take always an even number of elements.
    def method_missing(method_name, *args, **kwds)
      if DISABLED_ARRAY_METHODS.include? method_name
        raise NoMethodError, "no method "+method_name.to_s
      end
      _return_this_or_other{
        @array.public_send(method_name, *args, **kwds)
      }
    end

    # Redefines the behaviour of +respond_to?+ (essential when defining +method_missing+)
    def respond_to_missing?(method_name, *rest)  # include_all=false
      !DISABLED_ARRAY_METHODS.include?(method_name) && @array.respond_to?(method_name, *rest) || super
    end

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
      return @array[arg1] if !arg2 && !arg1.respond_to?(:exclude_end?)

      check_bracket_args_type_error(arg1, arg2)  # Args are now either (Int, Int) or (Range)

      if arg2
        size2ret = size2extract(arg1, arg2, ignore_error: true)  # maybe nil (if the index is too small).
        raise ArgumentError, ERR_MSGS[:even_num]+" "+ERR_MSGS[:use_to_a] if size2ret.odd?
        begin
          raise ArgumentError, "odd index is not allowed as the starting index for #{self.class.name}.  It must be even. "+ERR_MSGS[:use_to_a] if positive_array_index_checked(arg1, @array).odd?
        rescue TypeError, IndexError
          # handled by super
        end
        return _return_this_or_other{
          @array[arg1, arg2]
        }
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
        return _return_this_or_other{
          @array[arg1, *rest]
        }
      end

      raise RangeError, "odd index is not allowed as the starting Range for #{sefl.class.name}.  It must be even. "+ERR_MSGS[:use_to_a] if rang.begin.odd?
      size2ret = size2extract(rang, skip_renormalize: true)
      raise ArgumentError, ERR_MSGS[:even_num]+" "+ERR_MSGS[:use_to_a] if size2ret.odd?
      _return_this_or_other{
        @array[arg1, *rest]
      }
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
      if !arg2 && !arg1.respond_to?(:exclude_end?)
        return _return_this_or_other{
          @array[arg1] = val
        }
      end

      check_bracket_args_type_error(arg1, arg2)  # Args are now either (Int, Int) or (Range)

      # raise TypeError, "object to replace must be Array type with an even number of elements." if !val.respond_to?(:to_ary) || val.size.odd?

      vals = (val.to_ary rescue [val])
      if arg2
        size2delete = size2extract(arg1, arg2, ignore_error: true)  # maybe nil (if the index is too small).
        raise ArgumentError, "odd-even parity of size of array to replace must be identical to that to slice." if size2delete && ((size2delete % 2) != (vals.size % 2))
        return _return_this_or_other{
          @array[arg1] = val
        }
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
      @array[arg1] = val

      # The result may not be in an even number anymore.  Correct it.
      Boundary.insert(@array.size, "") if @array.size.odd?   ############## is it correct???

      # Original method may fill some elements of the array with String or even nil.  
      normalize!
    end

    # Array#insert
    #
    # The most basic method to add/insert elements to self.  Called from {#[]=} and {#push}, for example.
    #
    # The maximum permitted position index is the size of self,s
    # unlike +Array#insert+, which allows an index larger than the size,
    # in which case +nil+ is inserted in between.
    #
    # The number of the inserted elements must be always even.
    #
    # @param ind [Index] +rest+ is inserted *before* +ind+ if non-negative and *after* if negative.
    # @param rest [Array] This must have an even number of arguments.
    # @option primitive: [Boolean] if true (Def: false), no wrapper action is performed.
    # @return [self]
    def insert(ind, *rest, primitive: false)
      #return insert_original_b4_part(ind, *rest) if primitive
      return _return_this_or_other(@array.insert(ind, *rest)) if primitive

      ipos = positive_array_index_checked(ind, @array)  # IndexError may be raised.
      ipos += 1 if ind < 0
      # If ipos is negative, it should be inserted AFTER the index according to Array#index,
      # whereas if ipos is non-negative, inserted BEFORE.

      if ipos > @array.size
        raise IndexError, sprintf("index (%s) too large for array: maximum: %d.", ipos, @array.size)
      elsif rest.size.odd?
        raise ArgumentError, sprintf("number of arguments (%d) must be even.", rest.size)
      end

      return self if rest.empty?

      begin
        _return_this_or_other{
          @array.insert(ipos, *rest) && normalize! && self
        }
      rescue PlainText::PartNormalizeError => err
        raise TypeError, err.message
      end
    end


    # Delete elements and return the deleted content or nil if nothing is deleted.
    #
    # The number of elements to be deleted must be even.
    #
    # @param arg1 [Integer, Range]
    # @option arg2 [Integer, NilClass]
    # @option primitive: [Boolean] if true (Def: false), no wrapper action is performed.
    # @return as self or NilClass
    def slice!(arg1, *rest, primitive: false)
      #return slice_original_b4_part!(arg1, *rest) if primitive
      return _return_this_or_other(@array.slice(ind, *rest)) if primitive

      arg2 = rest[0]

      # Simple substitution to a single element
      raise ArgumentError, ERR_MSGS[:even_num] if !arg2 && !arg1.respond_to?(:exclude_end?)

      check_bracket_args_type_error(arg1, arg2)  # Args are now either (Int, Int) or (Range)

      if arg2
        size2delete = size2extract(arg1, arg2, ignore_error: true)  # maybe nil (if the index is too small).
        raise ArgumentError, ERR_MSGS[:even_num] if size2delete && size2delete.odd?
        raise ArgumentError, "odd index is not allowed as the starting Range for #{self.class.name}.  It must be even." if arg1.odd?  # Because the returned value is this class of instance.
        return _return_this_or_other(@array.slice!(arg1, *rest))
      end

      begin
        rang = normalize_index_range(arg1)
      rescue IndexError => err
        raise RangeError, err.message
      end

      raise RangeError if rang.begin < 0 || rang.end < 0

      return _return_this_or_other(@array.slice!(arg1, *rest)) if (rang.begin > rang.end)  # nil or [] is returned
      

      size2delete = size2extract(rang, skip_renormalize: true)
      raise ArgumentError, ERR_MSGS[:even_num] if size2delete && size2delete.odd? 
      raise ArgumentError, "odd index is not allowed as the starting Range for #{self.class.name}.  It must be even." if rang.begin.odd?  # Because the returned value is this class of instance.
      _return_this_or_other(@array.slice!(arg1, *rest))
    end
 
 
    ########## Other methods of Array ##########

    # Array#compact!
    #
    # If changed, re-{#normalize!} it.
    #
    # @return [self, NilClass]
    def compact!
      ret = @array.send(__method__)
      ret ? normalize!(recursive: false) : ret
    end

    # Array#concat
    #
    # @see #insert
    #
    # @param rest [Array<Array>]
    # @return [self]
    def concat(*rest)
      insert(@array.size, *(rest.sum([])))
    end

    # Array#push
    #
    # @see #concat
    #
    # @param rest [Array]
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
        raise TypeError, sprintf("no implicit conversion of #{arg2.class} into Integer") if !arg2.respond_to?(:to_int)
      else
        raise TypeError if !arg1.respond_to?(:exclude_end?)
      end
    end
    private :check_bracket_args_type_error
 
 
    # Emptifies all the Boundaries immediately before the index and squashes it to the one at it.
    #
    # @return [Boundary] all the descendants' last Boundaries merged.
    def emptify_last_boundary!
      return Boundary::Empty.dup if @array.size == 0
      ret = ""
      ret << prt.public_send(__method__) if prt.respond_to? __method__
      ret << @array[-1]
      @array[-1] = Boundary::Empty.dup
      ret
    end
    private :emptify_last_boundary!


    # Returns a positive Integer index guaranteed to be 1 or greater and smaller than the size.
    #
    # @param index [Integer]
    # @return [Integer, nil] nil if a too large index is specified.
    def get_valid_ipos_for_boundary(index)
      i_pos = positive_array_index_checked(index, @array)
      raise ArgumentError, "Index #{index} specified was for Para, which should be for Boundary." if index_para?(i_pos, accept_negative: false)
      (i_pos > size - 1) ? nil : i_pos
    end
    private :get_valid_ipos_for_boundary


    # Core routine for {#map_boundary} and similar.
    #
    # @option do_map opts: [Boolean] if true (Default), map is performed. Else just each.
    # @option with_index: [Boolean] if true (Default: false), yield with also index
    # @option recursive: [Boolean] if true (Default), map is performed recursively.
    # @return as self if map: is true, else void
    def map_boundary_core(do_map: true, with_index: false, recursive: true, **kwd, &bl)
      ind = -1
      arnew = @array.map{ |ec|
        ind += 1
        if recursive && index_para?(ind, accept_negative: false) && ec.respond_to?(__method__)
          ec.public_send(__method__, recursive: true, **kwd, &bl)
        elsif !index_para?(ind, accept_negative: false)
          with_index ? yield(ec, ind) : yield(ec)
        else
          ec
        end
      }
      self.class.new arnew, recursive: recursive, **kwd if do_map
    end
    private :map_boundary_core

    # Core routine for {#map_para}
    #
    # @option do_map: [Boolean] if true (Default), map is performed. Else just each.
    # @option with_index: [Boolean] if true (Default: false), yield with also index
    # @option recursive: [Boolean] if true (Default), map is performed recursively.
    # @return as self
    # @see #initialize for the other options (:compact and :compacter)
    def map_para_core(do_map: true, with_index: false, recursive: true, **kwd, &bl)
      ind = -1
      new_paras = paras.map{ |ec|
        ind += 1
        if recursive && ec.respond_to?(__method__)
          ec.public_send(__method__, recursive: true, **kwd, &bl)
        else
          with_index ? yield(ec, ind) : yield(ec)
        end
      }
      self.class.new new_paras, boundaries, recursive: recursive, **kwd if do_map
    end
    private :map_para_core

    # Core routine for {#normalize!} and {#normalize}
    #
    # @param ea [Array, String, NilClass] the element to evaluate
    # @param i [Integer] Main array index
    # @option recursive: [Boolean] if true (Default), normalize recursively.
    # @option ignore_array_boundary: [Boolean] if true (Default), even if a Boundary element (odd-numbered index) is an Array, ignore it.
    # @return [Part, Paragraph, Boundary]
    def normalize_core(ea, i, recursive: true, ignore_array_boundary: true)
      if    ea.respond_to?(:to_ary)
        if index_para?(i, accept_negative: false) || ignore_array_boundary
          (/\APlainText::/ =~ ea.class.name && defined?(ea.normalize)) ? (recursive ? ea.normalize : ea) : self.class.new(ea, recursive: recursive)
        else
          raise "Element at index ({#i}) is a Part or Array, but it should be Boundary or String."
        end
      elsif ea.respond_to?(:to_str)
        if   i.even? && self.class.boundary?(ea)
          msg = "not be Boundary"
        elsif i.odd? && self.class.paragraph?(ea)
          msg = "be neither Part nor Paragraph"
        end
        raise PlainText::PartNormalizeError, sprintf("Element at index=(%d) must %s", i, msg) if msg

        if /\APlainText::/ =~ ea.class.name
          # Paragraph or Boundary
          ea.unicode_normalize  # Unicode-normalized new object
        else
          if index_para?(i, accept_negative: false)
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
      arpair = [rng.begin, rng.end].to_a.map{ |i| positive_array_index_checked(i, @array, **kwd) }
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
        if arg1.respond_to? :exclude_end?
          rng = arg1
          rng = normalize_index_range(rng, **kwd) if !skip_renormalize
        else
          ipos = positive_array_index_checked(arg1, @array)
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
# require (after the module is defined)
####################################################

require_relative 'part/paragraph'
require_relative 'part/boundary'
require_relative "parse_rule"

#######
# idea
#   * Potentially, a specification of the main array of always an odd number of elements is possible: [Para, Boundary, B, P, B, P], either or both of the last and first of which may be empty.
#   * then joining is very straightforward.
#   * A trouble is, open/close tab structures like HTML/LaTeX-type (+<ul>...</ul>+) are not represented very well.
#
