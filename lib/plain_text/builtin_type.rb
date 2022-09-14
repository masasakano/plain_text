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
    # core routine for dup/clone
    #
    # @param copied [PlainText::Part] super-ed object
    # @param metho [Symbol] method name
    # @param varname [String] instance-variable name, e.g., +"@array"+
    # @return [Object] e.g., {PlainText::Part}, {PlainText::Part::Paragraph}
    def dup_or_clone(copied, metho, varname)
      val = (instance.send(metho)  rescue instance)  # rescue in case of immutable (though instance (e.g., @array) should never be so).
      copied.instance_variable_set(varname, val)
      # NOTE: copied.to_a.replace(val) would not work because it does not change @array.object_id
      #   A setter like {#to_a=} or {#instance=} would work, though polimorphism would break.
      copied 
    end
    private :dup_or_clone

  end # BuiltinType
end   # module PlainText

