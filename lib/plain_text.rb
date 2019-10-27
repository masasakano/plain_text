# -*- coding: utf-8 -*-

# Utility methods for mainly line-based processing of String
#
# This module contains methods useful in processing a String object of a text file,
# that is, a String that contains an entire or a multiple-line part of a text file.
# The methods include normalizing the line-break codes, removing extra spaces from each line, etc.
# Many of the methods work on tha basis of a line.  For example, {#head} and {#tail} methods
# work like the respective UNIX-shell commands, returning a specified line at the head/tail parts of self.
#
# Most methods in this module are meant to be included in String, except for a few module functions.
# It is however debatable whether it is a good practice to include a third-party module in the core class.
# This module contains a helper module function {PlainText.extend_this}, with which an object extends this module easily as Singleton if this module is not already included.
#
# A few methods in this module assume that {PlainText::Split} is included in String,
# which in default is the case, as soon as this file is read (by Ruby's require).
#
# @author Masa Sakano (Wise Babel Ltd)
#
module PlainText

  # List of the default line breaks.
  DefLineBreaks = [ "\r\n", "\n", "\r" ] # cf., Default in the present environment: $/

  # Default number of lines to extract for {#head} and {#tail}
  DEF_HEADTAIL_N_LINES = 10

  # Default options for class/instance methods
  DEF_METHOD_OPTS = {
    :clean_text => {
      preserve_paragraph: true,
      boundary_style: true,  # If unspecified, will be replaced with lb_out * 2
      lbs_style: :truncate,
      lb_is_space: false,
      sps_style: :truncate,
      delete_asian_space: true,
      linehead_style: :none,
      linetail_style: :delete,
      firstlbs_style: :delete,
      lastsps_style:  :truncate,
      lb: $/,
      lb_out: nil,           # If unspecified, will be replaced with lb
    },
    :count_char => {
      lbs_style: :delete,
      linehead_style: :delete,
      lastsps_style: :delete,
      lb_out: "\n",
    },
  }

  # Adjusts DEF_METHOD_OPTS[:count_char]
  DEF_METHOD_OPTS[:clean_text].each_key do |ek|
    # %i(preserve_paragraph boundary_style lb_is_space sps_style delete_asian_space linetail_style firstlbs_style lb).each do |ek|
    DEF_METHOD_OPTS[:count_char][ek] ||= DEF_METHOD_OPTS[:clean_text][ek]
  end

  # Call instance method as a Module function
  #
  # The return String includes {PlainText} as Singleton.
  #
  # @param method [Symbol] module method name
  # @param instr [String] String that is examined.
  # @return [#instr]
  def self.__call_inst_method__(method, instr, *rest, **k)
    newself = instr.clone
    PlainText.extend_this(newself)
    newself.public_send(method, *rest, **k)
  end

  # If the class of the obj does not "include" this module, do so in the singular class.
  #
  # @param obj [Object] Maybe String. For which a singular class def is run, if the condition is met.
  # @return [TrueClass, NilClass] true if the singular class def is run. Else nil.
  def self.extend_this(obj)
    return nil if defined? obj.delete_spaces_bw_cjk_european!
    obj.extend(PlainText)
    true
  end

  # Count the number of characters
  #
  # See {PlainText#clean_text!} for the optional parameters.  The defaults of a few of the optional parameters are different from it,
  # such as the default for +lb_out+ is +"\n"+ (newline, so that a line-break is 1 byte in size).
  # It is so that this method is more optimized for East-Asian (CJK) characters, given this method is most useful for CJK Strings,
  # whereas, for European alphabets, counting the number of words, rather than characters as in this method, would be more standard.
  #
  # @param instr [String] String for which the number of chars is counted
  # @param (see #count_char)
  # @return [Integer]
  def self.count_char(instr, *rest,
        lbs_style:      DEF_METHOD_OPTS[:count_char][:lbs_style],
        linehead_style: DEF_METHOD_OPTS[:count_char][:linehead_style],
        lastsps_style:  DEF_METHOD_OPTS[:count_char][:lastsps_style],
        lb_out:         DEF_METHOD_OPTS[:count_char][:lb_out],
        **k
      )
    clean_text(instr, *rest, lbs_style: lbs_style, linehead_style: linehead_style, lastsps_style: lastsps_style, lb_out: lb_out, **k).size
  end


  # Cleans the text
  #
  # Such as, removing extra spaces, normalising the linebreaks, etc.
  #
  # In default,
  #
  # * Paragraphs (more than 2 +\n+) are taken into account (one +\n+ between two): +preserve_paragraph=true+
  # * Blank lines are truncated into one line with no white spaces: +boundary_style=lb_out*2(=$/*2)+
  # * Consecutive white spaces are truncated into a single space: +sps_style=:truncate+
  # * White spaces before or after a CJK character is deleted: +delete_asian_space=true+
  # * Preceding white spaces in each line are preserved: +linehead_style=:none+
  # * Trailing white spaces in each line are deleted: +linetail_style=:delete+
  # * Line-breaks at the beginning of the entire input string are deleted: +firstlbs_style=:delete+
  # * Trailing white spaces and line-breaks at the end of the entire input string are truncated into a single linebreak: +lastsps_style=:truncate+
  #
  # For a String with predominantly CJK characters, the following setting is recommended:
  #
  # * +lbs_style: :delete+
  # * +delete_asian_space: true+ (Default)
  #
  # Note for the Symbols in optional arguments, the Symbol with the first character only is accepted,
  # e.g., +:d+ instead of +:delete+ (nb., +:t2+ for +:truncate2+).
  #
  # For more detail, see the description of each command-line options.
  #
  # Note that for the case of traditional genko-yoshi-style Japanese texts
  # with "jisage" for each new paragraph marking a new paragraph, probably
  # the best way is to make your own Part instance to give to this method,
  # where the rule for the Part should be something like:
  #   /(\A[[:blank:]]+|\n[[:space:]]+)/
  #
  # @param prt [PlainText:Part, String] {Part} or String to examine.
  # @param preserve_paragraph: [Boolean] Paragraphs are taken into account if true (Def: False). In the input, paragraphs are defined to be separated with more than one +lb+ with potentially some space characters in between. Their output style is specified with +boundary_style+.
  # @param boundary_style: [String, Symbol] One of +(:truncate|:truncate2|:delete|:none)+ or String. If String, the boundaries between paragraphs are replaced with this String (Def: +lb_out*2+).  If +:truncate+, consecutive linebreaks and spaces are truncated into 2 linebreaks.   +:truncate2+ are similar, but they are not truncated beyond 3 linebreaks (ie., up to 2 blank lines between Paragraphs). If +:none+, nothing is done about them. Unless :none, all the white spaces between linebreaks are deleted.
  # @param lbs_style: [Symbol] One of +(:truncate|:delete|:none)+ (Def: +:truncate+).  If :delete, all the linebreaks within paragraphs are deleted.  +:truncate+ is meaningful only when +preserve_paragraph=false+ and consecutive linebreaks are truncated into 1 linebreak.
  # @param sps_style: [Symbol] One of +(:truncate|:delete|:none)+ (Def: +:truncate+).  If +:truncate+, the consecutive white spaces within paragraphs, *except* for those at the line-head or line-tail (which are controlled by +linehead_style+ and +linehead_style+, respectively), are truncated into a single white space. If :delete, they are deleted.
  # @param lb_is_space: [Boolean] If true, a line-break, except those for the boundaries (unless +preserve_paragraph+ is false), is equivalent to a space (Def: False).
  # @param delete_asian_space: [Boolean] Any spaces between, before, after Asian characters (but punctuation) are deleted, if true (Default).
  # @param linehead_style: [Symbol] One of +(:truncate|:delete|:none)+ (Def: :none). Determine how to handle consecutive white spaces at the beggining of each line.
  # @param linetail_style: [Symbol] One of +(:truncate|:delete|:markdown|:none)+ (Def: :delete). Determine how to handle consecutive white spaces at the end of each line.  If +:markdown, 1 space is always deleted, and two or more spaces are truncated into two ASCII whitespaces *if* the last two spaces are ASCII whitespaces, or else untouched.
  # @param firstlbs_style: [Symbol, String] One of +(:truncate|:delete|:none)+ or String (Def: :default). If +:truncate+, any linebreaks at the very beginning of self (and whitespaces in between), if exist, are truncated to a single linebreak.  If String, they are, even if not exists, replaced with the specified String (such as a linebreak).  If +:delete+, they are deleted.  Note This option has nothing to do with the whitespaces at the beginning of the first significant line (hence the name of the option).  Note if a (random) Part is given, this option only considers the first significant element of it.
  # @param lastsps_style: [Symbol, String] One of +(:truncate|:delete|:none|:linebreak)+ or String (Def: :truncate). If +:truncate+, any of linebreaks *AND* white spaces at the tail of self, if exist, are truncated to a single linebreak.  If +:delete+, they are deleted.  If String, they are, even if not exists, replaced with the specified String (such as a linebreak, in which case +lb_out+ is used as String, i.e., it guarantees only 1 linebreak to exist at the end of the String).  Note if a (random) Part is given, this option only considers the last significant element of it.
  # @param lb: [String] Linebreak character like +\n+ etc (Default: $/). If this is one of the standard line-breaks, irregular line-breaks (for example, existence of CR when only LF should be there) are corrected.
  # @param lb_out: [String] Linebreak used for output (Default: +lb+)
  # @return same as prt
  #
  def self.clean_text(
        prt,
        preserve_paragraph: DEF_METHOD_OPTS[:clean_text][:preserve_paragraph],
        boundary_style:     DEF_METHOD_OPTS[:clean_text][:boundary_style], # If unspecified, will be replaced with lb_out * 2
        lbs_style:      DEF_METHOD_OPTS[:clean_text][:lbs_style],
        lb_is_space:    DEF_METHOD_OPTS[:clean_text][:lb_is_space],
        sps_style:      DEF_METHOD_OPTS[:clean_text][:sps_style],
        delete_asian_space: DEF_METHOD_OPTS[:clean_text][:delete_asian_space],
        linehead_style: DEF_METHOD_OPTS[:clean_text][:linehead_style],
        linetail_style: DEF_METHOD_OPTS[:clean_text][:linetail_style],
        firstlbs_style: DEF_METHOD_OPTS[:clean_text][:firstlbs_style],
        lastsps_style:  DEF_METHOD_OPTS[:clean_text][:lastsps_style],
        lb:     DEF_METHOD_OPTS[:clean_text][:lb],
        lb_out: DEF_METHOD_OPTS[:clean_text][:lb_out], # If unspecified, will be replaced with lb
        is_debug: false
      )

#isdebug = true if prt == "foo\n\n\nbar\n"
    lb_out ||= lb  # Output linebreak
    boundary_style = lb_out*2 if true       == boundary_style
    boundary_style = ""       if [:delete, :d].include? boundary_style
    lastsps_style  = lb_out   if :linebreak == lastsps_style

    if !prt.class.method_defined? :last_significant_element
      # Construct a Part instance from the given String.
      ret = ''
      begin
        prt = prt.unicode_normalize
      rescue ArgumentError  # (invalid byte sequence in UTF-8)
        warn "The given String in (#{self.name}\##{__method__}) seems wrong."
        raise
      end
      prt = normalize_lb(prt, "\n", lb_from: (DefLineBreaks.include?(lb) ? nil : lb)).dup
      kwd = (["\r\n", "\r", "\n"].include?(lb) ? {} : { rules: /#{Regexp.quote lb}{2,}/})
      prt = (preserve_paragraph ? Part.parse(prt, **kwd) : Part.new([prt]))
    else
      # If not preserve_paragraph, reconstructs it as a Part with a single Paragraph.
      # Also, deepcopy is needed, as this method is destructive.
      prt = (preserve_paragraph ? prt : Part.new([prt.join])).deepcopy
    end
    prt.squash_boundaryies!  # Boundaries are squashed.

    # Handles Boundary
    clean_text_boundary!(prt, boundary_style: boundary_style)

    # Handles linebreaks and spaces (within Paragraphs)
    clean_text_lbs_sps!( prt,
      lbs_style: lbs_style,
      lb_is_space: lb_is_space,
      sps_style: sps_style,
      delete_asian_space: delete_asian_space,
      is_debug: is_debug
    )
    # Handles the line head/tails.
    clean_text_line_head_tail!( prt,
      linehead_style: linehead_style,
      linetail_style: linetail_style
    )

    # Handles the file head/tail.
    clean_text_file_head_tail!( prt,
      firstlbs_style: firstlbs_style,
      lastsps_style:  lastsps_style,
      is_debug: is_debug
    )

    # Replaces the linebreaks to the specified one
    prt.map{ |i| i.gsub!(/\n/m, lb_out) }

    (ret ? prt.join : prt)  # prt.to_s may be different from prt.join
  end # def self.clean_text

  # Module function of {#delete_spaces_bw_cjk_european}
  #
  # @param (see #delete_spaces_bw_cjk_european)
  # @return as instr
  def self.delete_spaces_bw_cjk_european(instr, *rest)
    __call_inst_method__(:delete_spaces_bw_cjk_european, instr, *rest)
  end


  # Module function of {#head}
  #
  # The return String includes {PlainText} as Singleton.
  #
  # @param instr [String] String that is examined.
  # @param (see #head)
  # @return as instr
  def self.head(instr, *rest, **k)
    return PlainText.__call_inst_method__(:head, instr, *rest, **k)
  end


  # Module function of {#head_inverse}
  #
  # The return String includes {PlainText} as Singleton.
  #
  # @param instr [String] String that is examined.
  # @param (see #head_inverse)
  # @return as instr
  def self.head_inverse(instr, *rest, **k)
    return PlainText.__call_inst_method__(:head_inverse, instr, *rest, **k)
  end


  # Module function of {#normalize_lb}
  #
  # The return String includes {PlainText} as Singleton.
  #
  # @param instr [String] String that is examined.
  # @param (see #normalize_lb)
  # @return as instr
  def self.normalize_lb(instr, *rest, **k)
    return PlainText.__call_inst_method__(:normalize_lb, instr, *rest, **k)
  end


  # Module function of {#tail}
  #
  # The return String includes {PlainText} as Singleton.
  #
  # @param instr [String] String that is examined.
  # @param (see #tail)
  # @return as instr
  def self.tail(instr, *rest, **k)
    return PlainText.__call_inst_method__(:tail, instr, *rest, **k)
  end


  # Module function of {#tail_inverse}
  #
  # The return String includes {PlainText} as Singleton.
  #
  # @param instr [String] String that is examined.
  # @param (see #tail_inverse)
  # @return as instr
  def self.tail_inverse(instr, *rest, **k)
    return PlainText.__call_inst_method__(:tail_inverse, instr, *rest, **k)
  end


  ##########
  # Class methods (Private)
  ##########

  # @param prt [PlainText:Part] (see PlainText.clean_text)
  # @param boundary_style (see PlainText.clean_text)
  # @return [void]
  #
  # @see PlainText.clean_text
  def self.clean_text_boundary!( prt,
        boundary_style: ,
        is_debug: false
      )

    # Boundary
    case boundary_style
    when String
      prt.each_boundaries_with_index{|ec, i| ((i == prt.size - 1) && ec.empty?) ? ec : ec.replace(boundary_style)}
    when :truncate,  :t
      prt.boundaries.each{|ec| ec.gsub!(/[[:blank:]]+/m, ""); ec.gsub!(/\n+{3,}/m, "\n\n")}
    when :truncate2, :t2
      prt.boundaries.each{|ec| ec.gsub!(/[[:blank:]]+/m, ""); ec.gsub!(/\n+{4,}/m, "\n\n\n")}
    when :none, :n
      # Do nothing
    else
      raise ArgumentError
    end
  end # self.clean_text_boundary!
  private_class_method :clean_text_boundary!

  # @param prt [PlainText:Part] (see PlainText.clean_text)
  # @param lbs_style (see PlainText.clean_text)
  # @param sps_style (see PlainText.clean_text)
  # @param lb_is_space (see PlainText.clean_text)
  # @param delete_asian_space (see PlainText.clean_text)
  # @return [void]
  #
  # @see PlainText.clean_text
  def self.clean_text_lbs_sps!(
        prt,
        lbs_style:          ,
        lb_is_space:        ,
        sps_style:          ,
        delete_asian_space: ,
        is_debug: false
      )

    # Linebreaks and spaces
    case lbs_style
    when :truncate,   :t
      prt.parts.each{|ec| ec.gsub!(/\n{2,}/m, "\n")}
    when :delete,   :d
      prt.parts.each{|ec| ec.gsub!(/\n/m, "")}
    when :none, :n
      # Does nothing
    else
      raise ArgumentError
    end

    # Handles spaces in each line
    clean_text_sps!(prt, sps_style: sps_style, is_debug: is_debug)

    # Linebreaks become spaces
    if lb_is_space
      prt.parts.each{|ec| ec.gsub!(/\n/m, " ")}
      clean_text_sps!(prt, sps_style: sps_style, is_debug: is_debug) if sps_style == :truncate
    end

    # Ignore spaces between, before, and after Asian characters.
    if delete_asian_space
      prt.parts.each do |ea_p|
        PlainText.extend_this(ea_p)
        ea_p.delete_spaces_bw_cjk_european!  # Destructive change in prt.
      end
    end
  end # self.clean_text_lbs_sps!
  private_class_method :clean_text_lbs_sps!

  # @param prt [PlainText:Part] (see PlainText.clean_text)
  # @param linehead_style [Symbol, String] (see PlainText.clean_text)
  # @param linetail_style [Symbol, String] (see PlainText.clean_text)
  # @return [void]
  #
  # @see PlainText.clean_text
  def self.clean_text_line_head_tail!(
        prt,
        linehead_style: ,
        linetail_style: ,
        is_debug: false
      )

    # Head of each line
    case linehead_style
    when :truncate, :t
      prt.parts.each{|ec| ec.gsub!(/^[[:blank:]]+/, " ")}
    when :delete, :d
      prt.parts.each{|ec| ec.gsub!(/^[[:blank:]]+/, "")}
    when :none, :n
      # Do nothing
    else
      raise ArgumentError, "Invalid linehead_style (#{linehead_style.inspect}) is specified."
    end

    # Tail of each line
    case linetail_style
    when :truncate, :t
      prt.parts.each{|ec| ec.gsub!(/[[:blank:]]+$/, " ")}
    when :delete, :d
      prt.parts.each{|ec| ec.gsub!(/[[:blank:]]+$/, "")}
    when :markdown, :m
      # Two spaces are preserved
      prt.parts.each{|ec| ec.gsub!(/(?:^|(?<![[:blank:]]))[[:blank:]]$/, "")}  # A single space is deleted.
      prt.parts.each{|ec| ec.gsub!(/[[:blank:]]+  $/, "  ")}  # 3 or more spaces are truncated into 2 spaces, only IF the last two spaces are the ASCII spaces.
    when :none, :n
      # Do nothing
    else
      raise ArgumentError, "Invalid linetail_style (#{linetail_style.inspect}) is specified."
    end
  end # self.clean_text_line_head_tail!
  private_class_method :clean_text_line_head_tail!

  # @param prt [PlainText:Part] (see PlainText.clean_text#prt)
  # @param firstlbs_style [Symbol, String] (see PlainText.clean_text#firstlbs_style)
  # @param lastsps_style [Symbol, String]  (see PlainText.clean_text#lastsps_style)
  # @return [void]
  #
  # @see PlainText.clean_text
  def self.clean_text_file_head_tail!(
        prt,
        firstlbs_style: ,
        lastsps_style:  ,
        is_debug: false
      )

    # Handles the beginning of the given Part.
    obj = prt.first_significant_element || return
    # The first significant element is either Paragraph or Background.
    # obj may be nil.

    case firstlbs_style
    when String
      # This assumes the first Background is not
      #   (1) containing any non-space characters,
      #   (2) white-spaces only AND the first Paragraph starts from a linebreak.
      # You can assume it as long as String is the original input.
      # However, if the input is Part, anything can be possible, like
      # first multiple Backgrounds contain a linebreak for each, each of which
      # follows an empty Paragraph...
      #  The thing is, if String is always returned, it is much easier
      # to process after Part#join.  However, the method may return Part.
      # Therefore, you cannot do it!
      # I explain it in the document in {self.clean_text}.
      obj.sub!(/\A([[:space:]]*\n)?/m, firstlbs_style)
    when :truncate, :t
      # The initial blank lines, if exist, are truncated to a single "\n"
      obj.sub!(/\A[[:space:]]*\n/m, "\n")
    when :delete, :d
      # The initial blank lines are deleted.
      obj.sub!(/\A[[:space:]]*\n/m, "")
    when :none, :n
      # Do nothing
    else
      raise ArgumentError, "Invalid firstlbs_style (#{firstlbs_style.inspect}) is specified."
    end

    # Handles the end of the given Part.
    ind = prt.last_significant_index
    ind_para = (prt.index_para?(ind) ? ind : ind-1) # ind_para guaranteed to be for Paragraph
    obj = Part.new(prt[ind_para, 2]).join  # Handles as a String
    case lastsps_style
    when String
      # The trailing spaces and line-breaks, even if onot exist, are replaced with a specified String.
      changed = obj.sub!(/[[:space:]]*\z/m, lastsps_style)
    when :truncate, :t
      # The trailing spaces and line-breaks, if exist, are replaced with a single `linebreak_out`.
      changed = obj.sub!(/[[:space:]]+\z/m, "\n")
    when :delete, :d
      # The trailing spaces and line-breaks are deleted.
      changed = obj.sub!(/[[:space:]]+\z/m, "")
    when :none, :n
      # Do nothing
    else
      raise ArgumentError, "Invalid lastsps_style (#{lastsps_style.inspect}) is specified."
    end

    return nil if !changed
    ma = /^#{Regexp.quote prt[ind_para]}/.match obj
    if ma
    prt[ind_para].replace ma[0]
    prt[ind_para+1].replace ma.post_match
    else
    prt[ind_para].replace obj
    prt[ind_para+1].replace ""
    end
  end # self.clean_text_file_head_tail!
  private_class_method :clean_text_file_head_tail!


  # Handles spaces within Paragraphs
  #
  # uses Part to transform a Paragraph into a Part
  #
  # @param prt [PlainText:Part] (see PlainText.clean_text)
  # @param sps_style (see PlainText.clean_text)
  # @return [void]
  #
  # @see PlainText.clean_text
  def self.clean_text_sps!(
        prt,
        sps_style: ,
        is_debug: false
      )

    prt.parts.each do |e_pa|
      # Each line treated as a Paragraph, and [[:space:]]+ between them as a Boundary.
      # Then, to work on anything within a line except for line-head/tail is easy.
      prt_para = Part.parse(e_pa, rule: ParseRule::RuleEachLineStrip).map_parts { |e_li|
        case sps_style
        when :truncate, :t
          e_li.gsub(/[[:blank:]]{2,}/m, " ")
        when :delete, :d
          e_li.gsub(/[[:blank:]]+/m, "")
        when :none, :n
          e_li
        else
          raise ArgumentError
        end
      } # map_parts
      e_pa.replace prt_para.join
    end
  end
  private_class_method :clean_text_sps!


  ####################################################
  # Instance methods
  ####################################################

  # Count the number of characters
  #
  # See {PlainText.count_char} and further {PlainText.clean_text!} for the optional parameters.  The defaults of a few of the optional parameters are different from the latter,
  # such as the default for +lb_out+ is +"\n"+ (newline, so that a line-break is 1 byte in size).
  # It is so that this method is more optimized for East-Asian (CJK) characters, given this method is most useful for CJK Strings,
  # whereas, for European alphabets, counting the number of words, rather than characters as in this method, would be more standard.
  #
  # @param (see {PlainText.count_char})
  # @return [Integer]
  def count_char(*rest, **k)
    PlainText.public_send(__method__, self, *rest, **k)
  end

  # Delete all the spaces between CJK and European characters or numbers.
  #
  # All the spaces between CJK and European characters, numbers or punctuations
  # are deleted or converted into a specified replacement character.
  # Or, in short, any spaces between, before, and after a CJK characters are deleted.
  # If the return is non-nil, there is at least one match.
  #
  # @param repl [String] Replacement character (Default: "").
  # @return [MatchData, NilClass] MatchData of (one of) the last match if there is a positive match, else nil.
  def delete_spaces_bw_cjk_european!(repl="")
    ret = gsub!(/(\p{Hiragana}|\p{Katakana}|[ー－]|[一-龠々]|\p{Han}|\p{Hangul})([[:blank:]]+)([[:upper:][:lower:][:digit:][:punct:]])/, '\1\3')
    ret ||= gsub!(/([[:upper:][:lower:][:digit:][:punct:]])([[:blank:]]+)(\p{Hiragana}|\p{Katakana}|[ー－]|[一-龠々]|\p{Han}|\p{Hangul})/, '\1\3')
  end


  # Non-destructive version of {#delete_spaces_bw_cjk_european!}
  #
  # @param (see #delete_spaces_bw_cjk_european!)
  # @return same class as self
  def delete_spaces_bw_cjk_european(*rest)
    newself = clone
    newself.delete_spaces_bw_cjk_european!(*rest)
    newself
  end


  # Destructive version of {#head}
  #
  # @param (see #head)
  # @return [self]
  def head!(*rest, **key)
    replace(head(*rest, **key))
  end

  # Returns the first num lines (or characters, bytes) or before the last n-th line.
  #
  # If "byte" is specified as the return unit, the encoding is the same as self,
  # though the encoding for the returned String may not be valid anymore.
  # Note that it is probably the better practice to use +string[ 0..5 ]+ and +string#byteslice(0,5)+
  # instead of this method for the units of "char" and "byte", respectively.
  #
  # For num, a negative number means counting from the last (e.g., -1 (lines, if unit is :line) means
  # everything but the last 1 line, and -5 means everything but the last 5 lines), whereas 0 is forbidden.
  # If a too big negative number is given, such as -9 for String of 2 lines, a null string is returned.
  #
  # If unit is :line, num can be Regexp, in which case the string of the lines up to the *first* line
  # that matches the given Regexp is returned, where the process is based on the lines.  For example,
  # if num is +/ABC/+ (Regexp), String of the lines from the beginning up to the line that contains the character +"ABC"+ is returned.
  #
  # @param num_in [Integer, Regexp] Number (positive or negative, but not 0) of :unit to extract (Def: 10), or Regexp, which is valid only if unit is :line.
  # @param unit: [Symbol, String] One of +:line+ (or +"-n"+), :+char+, +:byte+ (or +"-c"+)
  # @param inclusive: [Boolean] read only when unit is :line. If inclusive (Default), the (entire) line that matches is included in the result.
  # @param linebreak: [String] +\n+ etc (Default: +$/+), used when +unit==:line+ (Default)
  # @return [String] as self
  def head(num_in=DEF_HEADTAIL_N_LINES, unit: :line, inclusive: true, linebreak: $/)
    if num_in.class.method_defined? :to_int
      num = num_in.to_int
      raise ArgumentError, "Non-positive num (#{num_in}) is given in #{__method__}" if num.to_int < 1
    elsif num_in.class.method_defined? :named_captures
      re_in = num_in
    else
      raise raise_typeerror(num_in, 'Integer or Range')
    end

    case unit
    when :line, "-n"
      # Regexp (for boundary)
      return head_regexp(re_in, inclusive: inclusive, linebreak: linebreak) if re_in

      # Integer (a number of lines)
      ret = split(linebreak)[0..(num-1)].join(linebreak)
      return ret if size <= ret.size  # Specified line is larger than the original or the last NL is missing.
      return(ret << linebreak)  # NL is added to the tail as in the original.
    when :char
      return self[0..(num-1)]
    when :byte, "-c"
      return self.byteslice(0..(num-1))
    else
      raise ArgumentError, "Specified unit (#{unit}.inspect) is invalid in #{__method__}"
    end
  end


  # Destructive version of {#head_inverse}
  #
  # @param (see #head_inverse)
  # @return [self]
  def head_inverse!(*rest, **key)
    replace(head_inverse(*rest, **key))
  end

  # Inverse of head - returns the content except for the first num lines (or characters, bytes)
  #
  # @param (see #head)
  # @return same as self
  def head_inverse(*rest, **key)
    s2 = head(*rest, **key)
    (s2.size >= size) ? '' : self[s2.size..-1]
  end

  # Normalizes line-breaks
  #
  # All the line-breaks of self are converted into a new character or \n
  # If the return is non-nil, self contains unexpected line-break characters
  # for the OS.
  #
  # @param repl [String] Replacement character (Default: +$/+ which is +\n+ in UNIX).
  # @param lb_from [String, Array, NilClass] Candidate line-break(s) (Defaut: +[CR+LF, CR, LF]+)
  # @return [MatchData, NilClass] MatchData of the last match if there is non-$/ match, else nil.
  def normalize_lb!(repl=$/, lb_from: nil)
    ret = nil
    lb_from ||= DefLineBreaks
    lb_from = [lb_from].flatten
    lb_from.each do |ea_lb|
      gsub!(/#{ea_lb}/, repl) if ($/ != ea_lb) || ($/ == ea_lb && repl != ea_lb)
      ret = $~ if ($/ != ea_lb) && !ret
    end
    ret
  end

  # Non-destructive version of {#normalize_lb!}
  #
  # @param (see #normalize_lb!)
  # @return same class as self
  def normalize_lb(*rest, **k)
    newself = clone  # must be clone (not dup) so Singlton methods, which may include this method, must be included.
    newself.normalize_lb!(*rest, **k)
    newself
  end


  # String#strip! for each line
  #
  # @param strip_head: [Boolean] if true (Default), spaces at each line head are removed.
  # @param strip_tail: [Boolean] if true (Default), spaces at each line tail are removed (see +markdown+ option).
  # @param markdown: [Boolean] if true (Def: false), a double space at each tail remains and +strip_head+ is forcibly false.
  # @param linebreak: [String] +\n+ etc (Default: +$/+)
  # @return [self, NilClass] nil if gsub! does not match at all, i.e., there are no spaces to remove.
  def strip_at_lines!(strip_head: true, strip_tail: true, markdown: false, linebreak: $/)
    strip_head = false if markdown
    r1 = strip_at_lines_head!(                    linebreak: linebreak) if strip_head
    r2 = strip_at_lines_tail!(markdown: markdown, linebreak: linebreak) if strip_tail
    (r1 || r2) ? self : nil
  end

  # Non-destructive version of {#strip_at_lines!}
  #
  # @param (see #strip_at_lines!)
  # @return same class as self
  def strip_at_lines(*rest, **k)
    newself = clone  # must be clone (not dup) so Singlton methods, which may include this method, must be included.
    newself.strip_at_lines!(*rest, **k)
    newself
  end


  # String#strip! for each line but only for the head part (NOT tail part)
  #
  # @param linebreak: [String] "\n" etc (Default: $/)
  # @return [self, NilClass] nil if gsub! does not match at all, i.e., there are no spaces to remove.
  def strip_at_lines_head!(linebreak: $/)
    lb_quo = Regexp.quote linebreak
    gsub!(/(\A|#{lb_quo})[[:blank:]]+/m, '\1')
  end

  # Non-destructive version of {#strip_at_lines_head!}
  #
  # @param (see #strip_at_lines_head!)
  # @return same class as self
  def strip_at_lines_head(*rest, **k)
    newself = clone  # must be clone (not dup) so Singlton methods, which may include this method, must be included.
    newself.strip_at_lines_head!(*rest, **k)
    newself
  end

  # String#strip! for each line but only for the tail part (NOT head part)
  #
  # @param markdown: [Boolean] if true (Def: false), a double space at each tail remains.
  # @param linebreak: [String] "\n" etc (Default: $/)
  # @return [self, NilClass] nil if gsub! does not match at all, i.e., there are no spaces to remove.
  def strip_at_lines_tail!(markdown: false, linebreak: $/)
    lb_quo = Regexp.quote linebreak
    return gsub!(/(?<=^|[^[:blank:]])[[:blank:]]+(#{lb_quo}|\z)/m, '\1') if ! markdown

    r1 = gsub!(/(?<=^|[^[:blank:]])[[:blank:]]{3,}(#{lb_quo}|\z)/m, '\1')
    r2 = gsub!(/(?<=^|[^[:blank:]])[[:blank:]](#{lb_quo}|\z)/m, '\1')
    (r1 || r2) ? self : nil
  end

  # Non-destructive version of {#strip_at_lines_tail!}
  #
  # @param (see #strip_at_lines_tail!)
  # @return same class as self
  def strip_at_lines_tail(*rest, **k)
    newself = clone  # must be clone (not dup) so Singlton methods, which may include this method, must be included.
    newself.strip_at_lines_tail!(*rest, **k)
    newself
  end


  # Destructive version of {#tail}
  #
  # @param (see #tail)
  # @return [self]
  def tail!(*rest, **key)
    replace(tail(*rest, **key))
  end

  # Returns the last num lines (or characters, bytes) or of and after the first n-th line.
  #
  # If "byte" is specified as the return unit, the encoding is the same as self,
  # though the encoding for the returned String may not be valid anymore.
  # Note that it is probably the better practice to use +string[ -5..-1 ]+ and +string#byteslice(-5,5)+
  # instead of this method for the units of "char" and "byte", respectively.
  #
  # For num, a negative number means counting from the first (e.g., -1 [lines, if unit is :line] means
  # everything but the first 1 line, and -5 means everything but the first 5 lines), whereas 0 is forbidden.
  # If a too big negative number is given, such as -9 for String of 2 lines, a null string is returned.
  #
  # If unit is :line, num can be Regexp, in which case the string of the lines *after* the *first* line
  # that matches the given Regexp is returned (*not* inclusive), where the process is based on the lines.  For example,
  # if num is /ABC/, String of the lines from the next line of the first line that contains the character "ABC"
  # till the last one is returned.  "The next line" means (1) the line immediately after the match
  # if the matched string has the linebreak at the end, or (2) the line after the first linebreak after the matched string,
  # where the trailing characters after the matched string to the linebreak (inclusive) is ignored.
  #
  # = Tips =
  # To specify the *last* line that matches the Regexp, consider prefixing +(?:.*)+ with the option +m+,
  # e.g., +/(?:.*)ABC/m+
  #
  # = Note for developers =
  #
  # The line that matches with Regexp has to be exclusive.  Because otherwise to specify the last line
  # that matches would be impossible in principle.  For example, to specify the *last* line that matches +ABC+,
  # the given regexp should be +/(?:.*)ABC/m+ (see the above Tips); in this case, if this matched line was inclusive,
  # *all the lines from Line 1* would be included, which is most likely not what the caller wants.
  #
  # @param num_in [Integer, Regexp] Number (positive or negative, but not 0) of :unit to extract (Def: 10), or Regexp, which is valid only if unit is :line.  If positive, the last num_in lines are returned.  If negative, the lines from the num-in-th line from the head are returned. In short, calling this method as +tail(3)+ and +tail(-3)+ is similar to the UNIX commands "tail -n 3" and "tail -n +3", respectively.
  # @param unit: [Symbol] One of :line (as in -n option), :char, :byte (-c option)
  # @param inclusive: [Boolean] read only when unit is :line. If inclusive (Default), the (entire) line that matches is included in the result.
  # @param linebreak: [String] +\n+ etc (Default: +$/+), used when unit==:line (Default)
  # @return [String] as self
  def tail(num_in=DEF_HEADTAIL_N_LINES, unit: :line, inclusive: true, linebreak: $/)
    if num_in.class.method_defined? :to_int
      num = num_in.to_int
      raise ArgumentError, "num of zero is given in #{__method__}" if num == 0
      num += 1 if num < 0
    elsif num_in.class.method_defined? :named_captures
      re_in = num_in
    else
      raise raise_typeerror(num_in, 'Integer or Range')
    end

    case unit
    when :line, '-n'
      # Regexp (for boundary)
      return tail_regexp(re_in, inclusive: inclusive, linebreak: linebreak) if re_in

      # Integer (a number of lines)
      return tail_linenum(num_in, num, linebreak: linebreak)
    when :char
      num = 0 if num >= size && num_in > 0
      return self[(-num)..-1]
    when :byte, '-c'
      num = 0 if num >= bytesize && num_in > 0
      return self.byteslice((-num)..-1)
    else
      raise ArgumentError, "Specified unit (#{unit}.inspect) is invalid in #{__method__}"
    end
  end

  # Destructive version of {#tail_inverse}
  #
  # @param (see #tail_inverse)
  # @return [self]
  def tail_inverse!(*rest, **key)
    replace(tail_inverse(*rest, **key))
  end

  # Inverse of tail - returns the content except for the first num lines (or characters, bytes)
  #
  # @param (see #tail)
  # @return same as self
  def tail_inverse(*rest, **key)
    s2 = tail(*rest, **key)
    (s2.size >= size) ? '' : self[0..(size-s2.size-1)]
  end


  ##########
  # Instance methods (private)
  ##########

  # head command with Regexp
  #
  # @param re_in [Regexp] Regexp to determine the boundary.
  # @param inclusive: [Boolean] If true (Default), the (entire) line that matches re_in is included in the result. Else the entire line is excluded.
  # @param linebreak: [String] +\n+ etc (Default: $/).
  # @return [String] as self
  # @see #head
  def head_regexp(re_in, inclusive: true, linebreak: $/)
    mat = re_in.match self
    return self if !mat
    if inclusive
      return mat.pre_match+mat[0]+post_match_in_line(mat, linebreak: linebreak)[0]
    else
      return pre_match_in_line(mat.pre_match, linebreak: linebreak).pre_match
    end
  end
  private :head_regexp


  # Returns MatchData of the String at and before the first linebreak before the MatchData (inclusive)
  #
  # @param strpre [String] String of prematch of the last MatchData
  # @param linebreak: [String] +\n+ etc (Default: $/)
  # @return [MatchData] m[0] is the string after the last linebreak before the matched data (exclusive) and m.pre_match is all the lines before that.
  def pre_match_in_line(strpre, linebreak: $/)
    lb_quo = Regexp.quote linebreak
    return /\z/.match(strpre) if /#{lb_quo}\z/ =~ strpre
    /(?:^|(?<=#{lb_quo}))[^#{lb_quo}]*?\z/m.match strpre  # non-greedy match and m option are required, as linebreak can be any characters.
  end
  private :pre_match_in_line

  # Returns MatchData of the String after the MatchData to the linebreak (inclusive)
  #
  # @param mat [MatchData, String]
  # @param strpost [String, nil] Post-match, if mat is String.
  # @param linebreak: [String] +\n+ etc (Default: $/)
  # @return [MatchData] m[0] is the string after matched data and up to the next first linebreak (inclusive) (or empty string if the last character(s) of matched data is the linebreak) and m.post_match is all the lines after that.
  def post_match_in_line(mat, strpost=nil, linebreak: $/)
    if mat.class.method_defined? :post_match
      # mat is MatchData
      strmatched, strpost = mat[0], mat.post_match
    else
      strmatched = mat.to_str rescue raise_typeerror(mat, 'String')
    end
    lb_quo = Regexp.quote linebreak
    return /\A/.match if /#{lb_quo}\z/ =~ strmatched
    /.*?#{lb_quo}/m.match strpost  # non-greedy match and m option are required, as linebreak can be any characters.
  end
  private :post_match_in_line

  # tail command with Regexp
  #
  # @param re_in [Regexp] Regexp to determine the boundary.
  # @param inclusive: [Boolean] If true (Default), the (entire) line that matches re_in is included in the result. Else the entire line is excluded.
  # @param linebreak: [String] +\n+ etc (Default: $/).
  # @return [String] as self
  # @see #tail
  def tail_regexp(re_in, inclusive: true, linebreak: $/)
    arst = split_with_delimiter re_in  # PlainText::Split#split_with_delimiter (included in String)
    return self.class.new("") if 0 == arst.size  # Maybe self is a sub-class of String.

    if inclusive
      return pre_match_in_line( arst[0..-3].join, linebreak: linebreak)[0] + arst[-2] + arst[-1]
      # Note: Even if (arst.size < 3), arst[0..-3] returns [].
    else
      return post_match_in_line(arst[-2], arst[-1], linebreak: linebreak).post_match
    end
  end
  private :tail_regexp


  # tail command based on the number of lines
  #
  # @param num_in [Integer] Original argument of the specified number of lines
  # @param num [Integer] Converted integer for num_in
  # @param linebreak: [String] +\n+ etc (Default: $/).
  # @return [String] as self
  # @see #tail
  def tail_linenum(num_in, num, linebreak: $/)
    arret = split(linebreak, -1)  # -1 is specified to preserve the last linebreak(s).
    return self.class.new("") if arret.empty?

    lb_quo = Regexp.quote linebreak
    if num_in > 0
      num += 1 if /#{lb_quo}\z/ =~ self
      num = 0  if num >= arret.size
    end
    ar = arret[(-num)..-1]
    (ar.nil? || ar.empty?) ? self.class.new("") : ar.join(linebreak)
  end
  private :tail_linenum


end # module PlainText

require "plain_text/part"
require "plain_text/parse_rule"
require "plain_text/split"
require "plain_text/util"

