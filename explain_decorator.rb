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
    # Uses `Object#method_missing` -= variable names will not be in the methods list so we 
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
    new_name_for_old_function = "#{func_name}_old".to_sym
    alias_method(new_name_for_old_function, func_name)

    define_method(func_name) do |*args, **kwargs|
      # if we're not asking for the explanation return early
      if ! kwargs.include?(:explain) && ! kwargs.include?(:explain_with_result) then
        return send(new_name_for_old_function, *args, **kwargs)
      end
      # start collecting context data
      m = method(new_name_for_old_function)
      
      # get method params and values for context
      parameters = m.parameters.map {|prm| prm[1] }
      params = {}
      parameters.each_with_index do |prm, i|
        params[prm] = args[i]
      end

      # get information on where the method is
      source_location = m.source_location.join(":")
      owning_class = m.receiver.class

      ctx = {
        **params,
        'source_class': owning_class,
        'source_location': source_location,
        'result': nil
      }

      # get result
      if kwargs.delete(:explain_with_result)
        ctx.merge!(kwargs)
        result = send(new_name_for_old_function, *args, **kwargs)
        ctx['result'] = result
        
        ERB.new(template).result_with_hash({
          **ctx,
          obj: ObjWrap.new(self),
          args: args,
        })
  
      elsif kwargs.delete(:explain)
        ctx.merge!(kwargs)
        ERB.new(template).result_with_hash({
          **ctx,
          obj: ObjWrap.new(self),
          args: args,
        })

      end
    end
  end
end
