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
    # We extend the old function by 'replacing' it - but to do that, we need to preserve
    # the old one so we can still call it from the snazzy new function.
    # puts params
    new_name_for_old_function = "#{func_name}_old".to_sym
    # This function, alias_method(), does what it says on the tin - allows us to call either
    # function name to do the same thing.  So now we have TWO references to the OLD function.
    # Note that alias_method is NOT a built-in function, but is a method of Class - that's one
    # reason we're doing this from a module.
    alias_method(new_name_for_old_function, func_name)
    # Here we're writing a new method with the name func_name.  Yes, that means we're REPLACING
    # the old method.
    
    define_method(func_name) do |*args, **kwargs|
      # get
      m = method(new_name_for_old_function)
      # get method params and values for context
      parameters = m.parameters.map {|prm| prm[1] }
      params = {}
      parameters.each_with_index do |prm, i|
        params[prm] = args[i]
      end
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
      else
        # This is the same as `self.send`.  `self` here is an instance of your extended class.  As we had TWO references to the original method, we still have one left over, so we can call it here.
        send(new_name_for_old_function, *args, **kwargs)
      end
    end
  end
end
