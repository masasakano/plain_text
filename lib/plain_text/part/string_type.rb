# -*- coding: utf-8 -*-

module PlainText
  class Part

    # Contains some utility methods for use in this module and classes.
    #
    # @author Masa Sakano (Wise Babel Ltd)
    #
    module StringType

      # Basically delegates everything to String
      def method_missing(method_name, *args, **kwds)
        ret = to_s.public_send(method_name, *args, **kwds)
        ret.respond_to?(:to_str) ? self.class.new(ret) : ret
      end

      # +Para("ab\ncd")+ or +Boundary("\n\n\n")+
      #
      # @return [String]
      def inspect
        s = self.class.name
        sprintf "%s(%s)", (s.split('::')[2..-1].join('::') rescue s), to_s.inspect
      end

      # Boundary sub-class name only
      #
      # Make sure your class is a child class of Boundary.
      # Otherwise this method would not be inherited, obviously.
      #
      # @example
      #   class PlainText::Part::Boundary
      #     class SubBoundary < self
      #       class SubSubBoundary < self; end  # Grandchild
      #     end
      #   end
      #   ss = PlainText::Part::SubBoundary::SubSubBoundary.new ["abc"]
      #   ss.subclass_name  # => "SubBoundary::SubSubBoundary"
      #
      # @return [String]
      # @see PlainText::Part#subclass_name
      def subclass_name
#printf "DEBUG: __method__=(%s)\n", __method__
        self.class.name.split(/\A#{Regexp.quote method(__method__).owner.name}::/)[1] || ''
      end

      ## @return [Integer, NilClass]
      #def <=>(other)
      #  return super if !other.respond_to? :to_str
      #  @string <=> other.to_str
      #end

      ## +String#==+ refers to this.
      ##
      ## @see https://ruby-doc.org/core-3.1.2/String.html#method-i-3D-3D
      #def ==(other)
      #  return super if !other.respond_to? :to_str
      #  @string == other.to_str
      #end

      # Core routine for comparison operators
      #
      # @example
      #    _equal_cmp(other, :==){ super }
      #    _equal_cmp(other, __method__){ super }
      # 
      # @return [Boolean, Integer, NilClass]
      def _equal_cmp(other, oper)
        return yield if !other.respond_to? :to_str
        to_s.send(oper, other)  # e.g., @string == other.to_str
      end
      private :_equal_cmp
    end # module StringType
  end   # class Part
end     # module PlainText

