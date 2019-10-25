# -*- coding: utf-8 -*-

module PlainText
  class Part < Array

    # Class to express a Paragraph as String
    #
    class Paragraph < String

      # @return [String]
      def inspect
        # 'Paragraph("abc\ndef")' or like 'Paragraph::Title("My Title")'
        s = self.class.name
        sprintf "%s(%s)", (s.split('::')[2..-1].join('::') rescue s), super
      end

      # Paragraph sub-class name
      #
      # Make sure your class is a child class of Paragraph.
      # Otherwise this method would not be inherited, obviously.
      #
      # @return [String]
      # @see PlainText::Part#subclass_name
      def subclass_name
        printf "__method__=(%s)\n", __method__
        self.class.name.split(/\A#{Regexp.quote method(__method__).owner.name}::/)[1] || ''
      end

      # Empty Paragraph instance
      Empty = self.new ""
      Empty.freeze
    end # class Paragraph < String
  end # class Part < Array
end # module PlainText

