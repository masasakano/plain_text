# -*- coding: utf-8 -*-

require_relative "../builtin_type"
require_relative "string_type"

module PlainText
  class Part

    # Class to express a Boundary, which behaves like a String
    #
    # This used to be a sub-class of String up to Ver.0.7.1
    #
    class Boundary
      include PlainText::BuiltinType
      include StringType

      # Constructor
      #
      # @param str [String]
      def initialize(str)
        @string = str
      end

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
        true
      end

      def paragraph?
        false
      end

      def part?
        false
      end

      # Empty Boundary instance
      Empty = self.new ""
      Empty.freeze
    end # class Boundary
  end # class Part
end # module PlainText

