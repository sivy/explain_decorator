require 'erb'

##
# Implements the `explanation` decorator method 
module ExplainDecorator
  ##
  # Lightweight wrapper to expose @variables to the ERB template
  #
  class ObjWrap
    ##
    #  The object to wrap
    def initialize(inst)
      @inst = inst
    end

    ##
    # Uses `Object#method_missing` - variable names will not be in the methods list so we 
    # know to pass them to `instance_variable_get` tro get a value.
    #
    # For example, to display @varname in the explanation template, use `obj.varname` 
    # (without the `@` unfortunately).
    def method_missing(attr)
      @inst.instance_variable_get("@#{attr}")
    end
  end


  ##
  # `explanation` monkey-patches wrapped methods so we can ask them to explain themselves
  # This code is heavily adapted from this SO post about python-style decorators in Ruby
  # https://stackoverflow.com/a/1893309
  #
  # This is the function that will DO the decoration: given a function, it'll extend it to 
  # have 'explanation' functionality. 
  def explanation(func_name, template)
    original = "#{func_name}_old".to_sym
    alias_method(original, func_name)
    decorator = self

    define_method(func_name) do |*args, **kwargs|
      explain = kwargs.delete(:explain)
      explain_with_result = kwargs.delete(:explain_with_result)

      # if we're not asking for the explanation, behave exactly like the original method
      unless explain || explain_with_result
        next send(original, *args, **kwargs)
      end

      ctx = decorator.send(:build_context, method(original), args, kwargs)
      ctx[:result] = send(original, *args, **kwargs) if explain_with_result

      ERB.new(template).result_with_hash({
        **ctx,
        obj: ObjWrap.new(self),
        args: args,
      })
    end
  end

  private

  ##
  # Collects the method's params and values, plus where it lives, for the ERB template
  def build_context(m, args, kwargs)
    params = m.parameters.map { |prm| prm[1] }.zip(args).to_h

    {
      **params,
      **kwargs,
      source_class: m.receiver.class,
      source_location: m.source_location.join(":"),
      result: nil
    }
  end
end
