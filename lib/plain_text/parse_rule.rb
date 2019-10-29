# -*- coding: utf-8 -*-

module PlainText

  # Class to describe rules to parse a String (and Array of them)
  #
  # An instance (say, +pr+) of this class describes how a String (or Array of them)
  # is parsed to a structure, that is, an Array of String or maybe
  # {PlainText::Part}, {PlainText::Part::Paragraph}, {PlainText::Part::Boundary}.
  # Once +pr+ is created, a String +str+ is parsed as
  #   ary = pr.apply(str)
  # which returns an Array (referred to as +ary+ hereafter).
  #
  # The returned array +ary+ may contain Strings at the basic level.  In that case,
  # any even elements are semantically {PlainText::Part::Boundary} and any odd elements are
  # semantically {PlainText::Part::Paragraph} or {PlainText::Part}, which can be further parsed
  # in the later processing.
  #
  # Alternatively, the returned array +ary+ may contain
  # {PlainText::Part::Paragraph}, {PlainText::Part::Boundary}, or even {PlainText::Part},
  # depending how the instance +pr+ is constructed.
  #
  # An instance +pr+ consists of an array of the rules (which can be retrieved by {#rules});
  # each rule of it is either a Proc instance or Regexp.
  # The rule is applied to either String (for the first-time application only)
  # or Array (for any subsequent applications), the latter of which is
  # (though it does not have to be) the result of the previous applications, and an Array is returned.
  # Elements of {#rules} (particularly common for for {#rules}[ 0 ]) can be Regexp,
  # in which case either the given String or every element of an even index (starting from 0;
  # they all are semantically Paragraphs) of the given Array is String#split as defined in the rule
  # to return an Array.  This manipulation with String#split in general increases the number of the elements
  # (Array#size) if an Array is given as the argument.  For example, suppose the given Array has initially two elements,
  # and suppose String#split is applied to the first element (only), and it may create 5 elements.  Then, the resultant
  # number of elements of the returned array is 6.
  #
  # For the second or later application, the element, Proc, must assume the argument is an Array
  # (of String or even {PlainText}::SOMETHING objects) and process them accordingly.
  #
  # For example, the predefined constant {PlainText::ParseRule::RuleConsecutiveLbs}
  # is one of the instances and it splits a String based on any consecutive linebreaks
  # (it is typical to regard paragraphs as being separated by consecutive linebreaks).
  # An example is like this:
  #
  #   pr.rules[0]  # => The rule is: PlainText::ParseRule::RuleConsecutiveLbs.rules[0]
  #                #  Once applied, the returned Array is like
  #                #   ["My story\n======\nHere is my report.",
  #                #    "\n\n", "abc", "\n\n", "xyz"]
  #   pr.rules[1]  # => /(\n={4,}\n)/
  #                #  Once applied, the returned Array is like
  #                #   ["My story", "\n======\n", "Here is my report.",
  #                #    "\n\n", "abc", "\n\n", "xyz"]
  #
  # Or another example may be like this:
  #
  #   pr.rules[0]  # => The rule: PlainText::ParseRule::RuleConsecutiveLbs.rules[0]
  #                #  Once applied, the returned Array is like
  #                #   ["# Breaking! #\nBy Mary Smith\n======\nHere is my report.",
  #                #    "\n\n", "abc", "\n\n", "xyz"]
  #   pr.rules[1]  # => The rule: For the first element of the input argument (Array), if it has one "\n======\n",
  #                #    it is regarded as a (the first) boundary, and the text before
  #                #    is regarded as {PlainText::Part}.  The returned Array is like
  #                #   [Part("# Breaking! #\nBy Mary Smith"),
  #                #    Boundary("\n======\n"),
  #                #    Paragraph("Here is my report."),
  #                #     "\n\n", "abc", "\n\n", "xyz"]
  #   pr.rules[2]  # => The rule: For the first element of the input argument (Array), if it satisfies /# (.+) #/,
  #                #    it is regarded as a title of a header.  The returned Array is like
  #                #   [Part::Header(Paragraph(""), Boundary("# "), Paragraph::Title("Breaking!"), Boundary(" #\n")),
  #                #    Boundary(""),
  #                #    Paragraph("By Mary Smith"),
  #                #    Boundary("\n======\n"),
  #                #    Paragraph("Here is my report."),
  #                #    "\n\n", "abc", "\n\n", "xyz"]
  #
  # With this, a {PlainText::Part} instance can be created like:
  #
  #   pt1 = PlainText::Part.parse(str, rule: pr)
  #
  # Then,
  #
  #   pt1.parts[0].parts[1] # => Paragraph::Title("Breaking!")
  #   pt1.boundaries[1]     # => Boundary("\n======\n")
  #
  # @todo
  #   It would be smarter each instance (Regexp and Part) has its own "name"
  #   rather than this class holds @names as an Array.
  #
  # @author Masa Sakano (Wise Babel Ltd)
  #
  class ParseRule

    # Main Array of rules (Proc or Regexp).  Do not delete or add the contents, as it would have a knock-on effect, especially with {#names}!
    # Use {#rule_at} to get a rule for the index/key.
    # The private method {#rule_at}(-1) is the same as {#rules}[-1],
    # but is more versatile and can be called like +#rules_at(:my_rule1, :my_rule2)+.
    attr_reader :rules

    # User-specified human-readable names Array, corresponding to each element of {#rules}.
    # The elements of this array are either String or nil, though it can be referred to as,
    # or set with {#set_name_at}, with Symbol.  In other words, an element of {#rules}
    # can be specified with a human-readable name, if set, as well as its index.
    # Use {#rule_at} to get a rule for the index/key.
    attr_reader :names

    # Constructor
    #
    # The main argument is a single or an Array of Proc or Regexp.
    # Alternatively, a block can be given.
    # If Regexp(s) is given, it should include grouping
    # (to enclose the entire Regexp usually).  If not, grouping is added forcibly.
    #
    # Note that the method (private method {#add_grouping}) wrongly recognizes patterns like +/[(x]/+ to contain grouping.
    # Also, it does not raise warning when more than one grouping is defined.
    # In fact, multiple groupings might be useful in some cases, such as,
    #   /(\n{2,})([^\n]*\S)([[:blank:]]*={2,}\n{2,})/
    # would produce, when applied, a series of
    #   [Paragraph, Boundary("\n\n"), Paragraph::Title, Boundary("==\n\n")]
    # Just make sure the number of groupings is an odd number, though.
    #
    # Optionally, when a non-Array argument or block is given, a name can be specified as the human-readable name for the rule.
    #
    # @option rule [ParseRule, Array, Regexp, Proc]
    # @param name: [String, Symbol]
    #
    # @yield [inprm] Block to register.
    # @yieldparam [String, Array<Part, Paragraph, Boundary>, Part] inprm Input String/Part/Array to apply the rule to.
    # @yieldreturn [Array] 
    def initialize(rule=nil, name: nil, &rule_block)
      if defined?(rule.rules) && defined?(rule.names)
        # ParseRule given
        @rules = rule.rules.clone.map{|i| i.clone rescue i} # Deep copy
        @names = rule.names.clone.map{|i| i.clone rescue i} # Deep copy
        return
      end

      if defined? rule.to_ary
        # Array given
        @rules = rule
        @names = Array.new(@rules.size)
        return
      end

      @rules = []
      @names = []
      push(rule, name: name, &rule_block)
    end


    # If no grouping is specified in Regexp, this method encloses it with '()'
    #
    # Because otherwise Boundaries would not be recognized.
    #
    # Note that this wrongly recognizes patterns like +/[(x]/+ to contain grouping.
    # Also, this does not raise warning when more than one grouping is defined.
    # In fact, multiple groupings might be useful in some cases, such as,
    #   /(\n{2,})([^\n]*\S)([[:blank:]]*={2,}\n{2,})/
    # would produce, when applied, a series of
    #   [Paragraph, Boundary("\n\n"), Paragraph::Title, Boundary("==\n\n")]
    # Just make sure the number of groupings is an odd number, though.
    #
    # @param rule_re [Regexp]
    # @return [Regexp]
    # @see PlainText::Split.add_grouping
    def add_grouping(rule_re)
      re_src = rule_re.source
      return rule_re if /(?<!\\)(?:(\\\\)*)\((?!\?:)/ =~ re_src

      # No "explicit" grouping is specified.  Hence adds it.
      Regexp.new '('+re_src+')', rule_re.options
    end
    private :add_grouping


    alias_method :clone_original_b4_parse_rule?, :clone if !method_defined? :clone_original_b4_parse_rule?

    # Deeper clone
    #
    # Without this, if @rules or @names are modified in a cloned instance,
    # even the original is affected.
    #
    # @return the same as self
    def clone
      ret = clone_original_b4_parse_rule?
      begin 
        ret.instance_eval{ @rules = rules.clone }
        ret.instance_eval{ @names = names.clone }
      rescue FrozenError
        warn "Instances in the original remain frozen after clone."
      end
      ret
    end


    alias_method :dup_original_b4_parse_rule?, :dup if !method_defined? :dup_original_b4_parse_rule?

    # Deeper dup
    #
    # Without this, if @rules or @names are modified in a dupped instance,
    # even the original is affected.
    #
    # @return the same as self
    def dup
      ret = dup_original_b4_parse_rule?
      ret.instance_eval{ @rules = rules.dup }
      ret.instance_eval{ @names = names.dup }
      ret
    end


    # Add a rule(s)
    #
    # If Regexp is given, it should include grouping (to enclose the entire Regexp usually).  If not, grouping is added forcibly.
    # Or, Proc or block can be given.
    # Consecutive rules can be given.  Note if a rule(s) is given, a block is ignored even if present.
    #
    # Any given rules, except the very first one, where the Proc argument is a String, should assume the Proc argument is an Array.
    # If Regexp is given for the second or later one, it will raise an Exception when {#apply}-ed.
    #
    # Optionally, providing non-Array argument or block is given, a name can be specified as the human-readable name for the rule.
    #
    # @option *rule [Regexp, Proc]
    # @param name: [String, Symbol, NilClass, Array<String, Symbol, NilClass>]  Array is not supported, yet.
    # @return [self]
    #
    # @yield [inprm] Block to register.
    # @yieldparam [String, Array<Part, Paragraph, Boundary>, Part] inprm Input String/Part/Array to apply the rule to.
    # @yieldreturn [Array] 
    def push(*rule, name: nil, &rule_block)
      #if rule.size > 1
      #  rule.each do |each_r|
      #    push each_r, rule_block
      #  end
      #  return self
      #end

      push_rule_core(*rule, &rule_block)
      set_name_at(name, -1) if !rules.empty?
# rulesize = ((0 != rule.size) ? rule.size : (block_given? ? 1 : 0))
### print "DEBUG-p: rulesize=#{rulesize}\n"
# arnames = (name ? [name].flatten : [])
# ((-rulesize)..-1).each_with_index do |i_rule, i_given|
#   set_name_at(arnames[i_given], i_rule)
# end if !rule.empty?
      self
    end

    # @option *rule [Regexp, Proc]
    # @return [self]
    #
    # @yield [inprm] Block to register.
    # @yieldparam [String, Array<Part, Paragraph, Boundary>, Part] inprm Input String/Part/Array to apply the rule to.
    # @yieldreturn [Array] 
    def push_rule_core(*rule, &rule_block)
      # If rule is given, it is guaranteed to be a single component.
      rule0 = rule[0]
      if rule0
        raise ArgumentError, "Argument and block are not allowed to be given simultaneously." if block_given?
        if defined?(rule0.source) && defined?(rule0.options)
          # Regexp given
          @rules.push add_grouping(rule0)
          return self
        end

        if defined? rule0.lambda?
          # Proc given
          @rules.push rule0
          return self
        end

        raise ArgumentError, "Invalid rule is given."
      end

      raise ArgumentError, "Neither an argument nor block is given." if !block_given?

      @rules.push rule_block
      self
    end
    private :push_rule_core

    # Set (or reset) a human-readable name for {#rules} at a specified index
    #
    # @param name [NilClass, #to_s] nil to reset or a human-readable name, usually either String or Symbol
    # @param index_rules [Integer] Index for {#rules}. A negative index is allowed.
    # @return [Integer] Non-negative index where name is set; i.e., if index=-1 is specified for {#rules} with a size of 3, the returned value is 2 (the last index of it).
    def set_name_at(name, index_rules)
      index = PlainText::Util.positive_array_index_checked(index_rules, @rules, accept_too_big: false, varname: 'rules')
      if !name
        @names[index] = nil
        return index
      end
      ns = name.to_s 
      index_exist = @names.find_index(ns)
      raise "Name #{ns} is already used for the index #{index}" if index_exist && (index_exist != index)
      @names[index] = ns
      index
    end


    # Get a rule for the specified index or human-readable key
    #
    # @param key [Integer, String, Symbol] Key for @rules
    # @return [Proc, Regexp, NilClass] nil if the specified rule is not found.
    def rule_at(key)
      begin
        ( defined?(key.to_int) ? @rules[key.to_int] : @rules[@names.find_index(key.to_s)] )
      rescue TypeError  # no implicit conversion from nil to integer
        nil
        # raise TypeError, "Specified key (#{key.inspect}) is not found for the rules among the registered names=#{@names.inspect}"
      end
    end


    # Get an array of rules for the specified indices or human-readable keys
    #
    # If an Array or sequence of arguments is given, it can be a combination of Integer and String/Symbol,
    # and the order of the elements in the returned Array corresponds to the input.
    #
    # @param keys [Array, Integer, Range, String, Symbol] Key for @rules
    # @return [Proc, Regexp]
    def rules_at(keys, *rest)
      if defined?(keys.exclude_end?)
        return @rules[keys]
      end
      ([keys]+rest).flatten.map{ |i| rule_at(i) }
    end
    private :rules_at


    # Pop a rule(s)
    #
    # @option *rest [Integer]
    # @return [Proc, Array<Proc>] if no argument is given, Proc is returned.
    def pop(*rest)
      if (rest.size == 0)
        (@rules.size > 0) ? @names.slice!((@rules.size-1)..-1) : @names.clear
      else
        i_beg = @rules.size - rest[0]
        i_beg = 0 if i_beg < 0
        @names.slice!(i_beg..-1) 
      end
      (rest.size == 0) ? @rules.pop : @rules.pop(*rest)
    end


    # Apply the rules to a given String
    #
    # In default, all the rules are applied in the registered sequence, unless an Option is specified
    #
    # This method receives either String (for the first-time application only)
    # or Array (for any subsequent applications), the latter of which is
    # (though not necessarily) the result of the previous applications,
    # applies the {#rules} one by one sequentially, and returns an Array.
    #
    # Elements of {#rules} can be Regexp (particularly common for for {#rules}[0]).
    # In that case, if the given argument is a String, String#split is simply applied.
    # If it is an Array, String#split is applied to every element of an even index
    # (starting from 0; n.b., all even-index elements are semantically Paragraphs).
    # Importantly, this manipulation with String#split to Array unfolds the result
    # of split on the spot, which means in general it increases
    # the number of the elements (Array#size) from the given one.  For example,
    # suppose the given Array has initially two elements and then String#split
    # is applied to the first element only (because it is the only even-index element).
    # Suppose the application creates 3 elements. They are interpreted as
    # a sequence of Paragraph, Boundary, and Paragraph.  Then the returned array
    # will contain 4 elements.  Or, suppose the split application to the first element
    # of the given array resulted in an array of 4 elements.  Then, the last element
    # of this array and the next element of the original array are both Boundary.
    # In this case, the two Boundaries are merged so that the elements of
    # the returned array are in the right order of Paragraphs and Boundaries.
    #
    # @example String input
    #   pr = PlainText::Part::ParseRule /(\n)/
    #   pr.rules  #=> [/(\n)/]
    #   pr.apply(["abc==def==\n"])
    #     #=> ["abc==def==", "\n"])
    #
    # @example Array input
    #   pr.rules  #=> [/(==)/]
    #   pr.apply(["abc==def==", "\n"])
    #     #=> ["abc", "==", "def", "==\n"])
    #
    # @example String input, sequential processing
    #   pr.rules  #=> [/(\n)/, /(==)/]
    #   pr.apply(["abc==def==\n"])
    #     #=> ["abc", "==", "def", "==\n"])
    #
    # @example Regexp and Proc rules, applied one by one.
    #   pr = PlainText::Part::ParseRule /(==(?:\n)?)/, index: 'my_first'
    #   pr.push{ |i| i.map{|j| ("def"==j) ? PlainText::Part::Paragraph(j) : j}}
    #   pr.rules
    #     #=> [/(==(?:\n)?)/, Proc{ |i| i.map{|j| ("def"==j) ? i.upcase : j}}]
    #   ar0 = pr.apply(["abc==def==\n"], index: 'my_first')
    #     #=> ["abc", "==", "def", "==\n"])
    #   pr.apply ar0, index: 1
    #     #=> ["abc", "==", "DEF", "==\n"])
    #
    # @param inprm [String, Array, PlainText::Part]
    # @param index: [Array, Range, Integer, String, Symbol] If given, the rule(s) at the given index (indices) or key(s) only are applied in the given order.
    # @return [Array] array of String, Paragraph, Boundary, Array, Part, etc
    def apply(inprm, index: nil, from_string: true, from_array: true)
      allrules = (index ? rules_at(index) : @rules)

      arret = (inprm.class.method_defined?(:to_ary) ? inprm : [inprm])
      allrules.each do |each_r|
        arret = (defined?(each_r.match) ? apply_split(arret, each_r) : each_r.call(arret))
      end
      arret
    end

    # Apply String#split with Regexp
    #
    # If an Array is given, Regexp is applied to each of even-number elements,
    # which are supposed to be {Paragraph}, one by one and recursively.
    #
    # @param inprm [String, Array, PlainText::Part]
    # @param re [Regexp]
    # @return [Array]
    def apply_split(inprm, re)
      return inprm.split re if !defined? inprm.to_ary

      hsflag = { concat_bd: false }  # whether concatnate Boundary to the previous one as a String.
      arret = []
      inprm.each_with_index do |ea_e, i|
        if i.odd?
          if !hsflag[:concat_bd]
            arret << ea_e
            next
          end
          if defined? ea_e.to_ary
            # The given argument (by the user) is wrong!  Boundary is somehow an Array.
            # Here, an empty string is added, emulating an empty Paragraph. 
            arret << "" << ea_e
          else
            # Boundary is concatnated with the previous one.
            arret[-1] << ea_e
          end
          hsflag[:concat_bd] = false
          next
        end

        ar = apply_split(ea_e, re)

        if (defined? ea_e.to_ary)
          # The processed Array(Part) simply replaces the existing one (no change of the size of the given array).
          arret << ar
        else
          # String(Paragraph) is split further and concatnated on the spot.
          ar = [""] if ar.empty?
          arret.concat ar
          hsflag[:concat_bd] = true if ar.size.even? # The next element (Boundary) should be appended to the last element as String.
        end
      end
      arret
    end
    private :apply_split

    # @return [Integer] The number of defined rules.
    def size
      si_rules = rules.size
      si_names = names.size
      if si_rules != si_names
        warn "WARNING: Inconsistent sizes for between rules (#{si_rules}) and names (#{si_names})."
      end
      si_rules
    end

    def_lb_q = PlainText::DefLineBreaks.map{|i| Regexp.quote i}.join '|'

    # {ParseRule} instance to
    # split a String with 2 or more linebreaks (with potentially white-spaces in between).
    # This instance can be dup-ped and used normally. However, if it is clone-d, the cloned instance would be unmodifiable.
    RuleConsecutiveLbs = self.new(/((?:#{def_lb_q})(?:#{def_lb_q}|[[:blank:]])*(?:#{def_lb_q}))/, name: 'ConsecutiveLbs') # => /((?:\r\n|\n|\r){2,}/
    RuleConsecutiveLbs.freeze
    RuleConsecutiveLbs.rules.freeze
    RuleConsecutiveLbs.names.freeze

    # {ParseRule} instance to
    # split a String with 1 linebreak that is potentially sandwiched with white-spaces
    # (or a whitespace(s) at the very beginning or end).
    # Essentially, each line (after Ruby-strip-ped) is treated as Paragraph.
    # This instance can be dup-ped and used normally. However, if it is clone-d, the cloned instance would be unmodifiable.
    RuleEachLineStrip = self.new(/(\A[[:space:]]+|[[:space:]]*\n[[:space:]]*|[[:space:]]+\z)/, name: 'EachLineStrip') # => /((?:\r\n|\n|\r){2,}/
    RuleEachLineStrip.freeze
    RuleEachLineStrip.rules.freeze
    RuleEachLineStrip.names.freeze
  end # class ParseRule
end # module PlainText

