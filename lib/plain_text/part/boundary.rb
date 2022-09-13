# -*- coding: utf-8 -*-

require_relative "string_type"

module PlainText
  class Part

    # Class to express a Boundary, which behaves like a String
    #
    # This used to be a sub-class of String up to Ver.0.7.1
    #
    class Boundary
      include StringType

      # Constructor
      #
      # @param str [String]
      def initialize(str)
        @string = str
      end

      ## @return [String]
      #def inspect
      #  # 'Boundary("\n\n\n")'
      #  s = self.class.name
      #  sprintf "%s(%s)", (s.split('::')[2..-1].join('::') rescue s), @string.inspect
      #end
#
#      # Boundary sub-class name only
#      #
#      # Make sure your class is a child class of Boundary.
#      # Otherwise this method would not be inherited, obviously.
#      #
#      # @example
#      #   class PlainText::Part::Boundary
#      #     class SubBoundary < self
#      #       class SubSubBoundary < self; end  # Grandchild
#      #     end
#      #   end
#      #   ss = PlainText::Part::SubBoundary::SubSubBoundary.new ["abc"]
#      #   ss.subclass_name  # => "SubBoundary::SubSubBoundary"
#      #
#      # @return [String]
#      # @see PlainText::Part#subclass_name
#      def subclass_name
##printf "DEBUG: __method__=(%s)\n", __method__
#        self.class.name.split(/\A#{Regexp.quote method(__method__).owner.name}::/)[1] || ''
#      end

      # @return [String]
      def to_s
        @string
      end
      alias_method :to_str, :to_s

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

      # Empty Boundary instance
      Empty = self.new ""
      Empty.freeze
    end # class Boundary
  end # class Part
end # module PlainText

