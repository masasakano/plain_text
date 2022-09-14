# -*- coding: utf-8 -*-

require_relative "../builtin_type"
require_relative "string_type"

module PlainText
  class Part

    # Class to express a Paragraph as String
    #
    class Paragraph
      include PlainText::BuiltinType
      include StringType

      # Constructor
      #
      # @param str [String]
      def initialize(str)
        @string = str
      end

      ## @return [String]
      #def to_s
      #  @string
      #end
      #alias_method :to_str, :to_s

      # @return [Integer, NilClass]
      def <=>(other)
        _equal_cmp(other, __method__){ super }
      end

      # +String#==+ refers to this.
      #
      # @see https://ruby-doc.org/core-3.1.2/String.html#method-i-3D-3D
      def ==(other)
        _equal_cmp(other, __method__){ super }
      end

      def boundary?
        false
      end

      def paragraph?
        true
      end

      def part?
        false
      end

      # Empty Paragraph instance
      Empty = self.new ""
      Empty.freeze
    end # class Paragraph
  end # class Part
end # module PlainText

