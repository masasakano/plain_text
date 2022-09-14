# -*- coding: utf-8 -*-

module PlainText

  # Contains common methods for builtin-class emulating classes
  #
  # The class that includes this module should have a method +instance+
  # that returns the main instance of the builtin-class instance;
  # e.g., +instance+ may be equivalent to +to_s+, +to_a+, and alike.
  #
  # @author Masa Sakano (Wise Babel Ltd)
  #
  module BuiltinType
    # Subclass name only
    #
    # Make sure your class is a child class of {PlainText::Part},
    # {PlainText::Part::Paragraph}, or {PlainText::Part::Boundary}.
    # Otherwise this method would not be inherited, obviously.
    #
    # @example For a child class of Part
    #   class PlainText::Part
    #     class Section < self
    #       class Subsection < self; end  # It must be a child class!
    #     end
    #   end
    #   ss = PlainText::Part::Section::Subsection.new ["abc"]
    #   ss.subclass_name         # => "Part::Section::Subsection"
    #   ss.subclass_name(index_ini: 1) # => "Section::Subsection"
    #
    # @example For a child class of Boundary
    #   class PlainText::Part::Boundary
    #     class SubBoundary < self
    #       class SubSubBoundary < self; end  # Grandchild
    #     end
    #   end
    #   ss = PlainText::Part::Boundary::SubBoundary::SubSubBoundary.new ["abc"]
    #   ss.subclass_name  # => "Part::Boundary::SubBoundary::SubSubBoundary"
    #   ss.subclass_name(index_ini: 2)    # => "SubBoundary::SubSubBoundary"
    #
    # @param index_ini [Integer] Starting index after split, e.g., if 1, +"Part::"+ is removed and if 2, "Part::Boundary::" (for example) is removed.
    # @return [String]
    # @see PlainText::Part#subclass_name
    def subclass_name(index_ini: 0)
      self.class.name.split(/\A#{Regexp.quote method(__method__).owner.name.split("::")[0..-2].join("::")}::/)[1].split('::')[index_ini..-1].join('::') || ''  # removing "::BuiltinType"
    end

    # core routine for dup/clone
    #
    # @param copied [PlainText::Part] super-ed object
    # @param metho [Symbol] method name
    # @param varname [String] instance-variable name, e.g., +"@array"+
    # @return [Object] e.g., {PlainText::Part}, {PlainText::Part::Paragraph}
    def dup_or_clone(copied, metho, varname)
      val = (instance.send(metho)  rescue instance)  # rescue in case of immutable (though instance (e.g., @array) should never be so and in fact it would not raise an Exception in Ruby 3 seemingly).
      copied.instance_variable_set(varname, val)
      # NOTE: copied.to_a.replace(val) would not work because it does not change @array.object_id
      #   A setter like {#to_a=} or {#instance=} would work, though polimorphism would break.
      copied 
    end
    private :dup_or_clone

  end # BuiltinType
end   # module PlainText

