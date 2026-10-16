require 'erb'

##
# Background
# ----------
#
# When implementing formulas and calculations in code, it can be useful for auditing or 
# troubleshooting to see the exact formula implemented alongside the actual arguments used 
# in a given call.
#
# `ExplainDecorator`` provides a method `explanation` that takes the method to be explained
# and en ERB template, and adds to posisble keyword args to the wrapped method: `explain:` 
# and `explain_with_result`
#
# Usage
# -----
# Use `extend ExplainDecorator` to add the `explanation` method to your class.
# 
# In the class, to add an explanation for a method:
# 
# ```
# class Calculator
#   def calculate(x, y)
#     x+y
#   end
#   explantation(:calculate, <<~EXP
#     calculate adds two integers
#     x + y
#     <%= x %> + <%= y %>
#   EXP
#   )
# end
# ```
#
# When calling the method, adding `expain: true` to the method call will, instead of the method's 
# expected result, a string based on the template string provided in `explanation`. In the example 
# above, calling `Calculator.new.calculate(1, 2, explain: true)` will return:
# 
#     calculate adds two integers
#     x + y
#     1 + 2
#
#
module ExplainDecorator
  ##
  # lightweight wrapper to expose @variables to the ERB template
  class ObjWrap
    def initialize(inst)
      @inst = inst
    end

    def method_missing(attr)
      @inst.instance_variable_get("@#{attr}")
    end
  end


  ##
  # `explanation` monkey-patches wrapped methods so we can ask them to explain themselves
  def explanation(func_name, template)
    # This is the function that will DO the decoration: given a function, it'll extend it to 
    # have 'explanation' functionality.
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
      m = method(new_name_for_old_function)
      # p "#{new_name_for_old_function} methods: #{m.methods}"
      # p "#{new_name_for_old_function} receiver: #{m.receiver}"
      # p "#{new_name_for_old_function} inspect: #{m.inspect}"
      # p "#{new_name_for_old_function} source_location #{m.source_location}"
      # p "#{new_name_for_old_function} parameters #{m.parameters}"

      # get method params and values for context
      parameters = m.parameters.map {|prm| prm[1] }
      params = {}
      parameters.each_with_index do |prm, i|
        params[prm] = args[i]
      end
      source_location = m.source_location.join(":")

      ctx = {
        **params, 
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
        puts "explaining with #{kwargs}"
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
