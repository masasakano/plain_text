# -*- coding: utf-8 -*-

module PlainText
  class Part

    # Contains common methods for use in the String-type classes.
    #
    # @author Masa Sakano (Wise Babel Ltd)
    #
    module StringType

      # @return [String]
      def to_s
        @string
      end
      alias_method :to_str,   :to_s
      alias_method :instance, :to_s  if ! self.method_defined?(:instance)

      # Basically delegates everything to String
      def method_missing(method_name, *args, **kwds)
        ret = to_s.public_send(method_name, *args, **kwds)
        ret.respond_to?(:to_str) ? self.class.new(ret) : ret
      end

      # Redefines the behaviour of +respond_to?+ (essential when defining +method_missing+)
      def respond_to_missing?(method_name, *rest)  # include_all=false
        to_s.respond_to?(method_name, *rest) || super
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
      #   ss = PlainText::Part::Boundary::SubBoundary::SubSubBoundary.new ["abc"]
      #   ss.subclass_name  # => "Boundary::SubBoundary::SubSubBoundary"
      #
      # @return [String]
      # @see PlainText::Part#subclass_name
      def subclass_name
#printf "DEBUG: __method__=(%s)\n", __method__
        self.class.name.split(/\A#{Regexp.quote method(__method__).owner.name.split("::")[0..-2].join("::")}::/)[1] || ''  # removing "::StringType"
      end

      # Work around because Object#dup does not dup the instance variable @string
      #
      # @return [PlainText::Part]
      def dup
        dup_or_clone(super, __method__, '@string')
      end

      # Work around because Object#clone does not clone the instance variable @string
      #
      # @return [PlainText::Part]
      def clone
        dup_or_clone(super, __method__, '@string')
      end

      # Core routine for comparison operators
      #
      # @example
      #    _equal_cmp(other, :==){ super }
      #    _equal_cmp(other, __method__){ super }
      #
      # @return [Boolean, Integer, NilClass]
      def _equal_cmp(other, oper)
        return yield if !other.respond_to? :to_str
        to_s.send(oper, other.to_str)  # e.g., @string == other.to_str
      end
      private :_equal_cmp
    end # module StringType
  end   # class Part
end     # module PlainText

