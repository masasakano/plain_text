# -*- coding: utf-8 -*-

module PlainText
  class Part < Array

    # Class to express a Boundary as String
    #
    class Boundary < String

      # @return [String]
      def inspect
        # 'Boundary("\n\n\n")'
        s = self.class.name
        sprintf "%s(%s)", (s.split('::')[2..-1].join('::') rescue s), super
      end

      # Boundary sub-class name only
      #
      # Make sure your class is a child class of Boundary.
      # Otherwise this method would not be inherited, obviously.
      #
      # @example
      #   class PlainText::Part::Boundary
      #     class SubBoundary < self
      #       class SubBoundary < self; end  # It must be a child class!
      #     end
      #   end
      #   ss = PlainText::Part::SubBoundary::SubSubBoundary.new ["abc"]
      #   ss.subclass_name  # => "SubBoundary::SubSubBoundary"
      #
      # @return [String]
      # @see PlainText::Part#subclass_name
      def subclass_name
        printf "__method__=(%s)\n", __method__
        self.class.name.split(/\A#{Regexp.quote method(__method__).owner.name}::/)[1] || ''
      end

      # Empty Boundary instance
      Empty = self.new ""
      Empty.freeze
    end # class Boundary < String
  end # class Part < Array
end # module PlainText

