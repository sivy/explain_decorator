Rdoc on Github Pages: https://sivy.github.io/explain_decorator/

Source: https://github.com/sivy/explain_decorator

## Background

When implementing formulas and calculations in code, it can be useful for auditing or 
troubleshooting to see the exact formula implemented alongside the actual arguments used 
in a given call.

`ExplainDecorator` provides a method `explanation` that takes the method to be explained
and an ERB template, and adds two keyword args to the wrapped method: `explain:` 
and `explain_with_result`. These control the output of the wrapped method.

## Usage

Use `extend ExplainDecorator` to add the `explanation` method to your class.

In the class, to add an explanation for a method:

```ruby
class Calculator
  extend ExplainDecorator

  def calculate_tax(x, y)
    x+y
  end
  # now wrap to support explanation
  explanation(:calculate, <<~EXP
    calculate adds two integers
    x + y
    <%= x %> + <%= y %>
    <% if result %>Result => <%= result %><% end %>
  EXP
  )
end
```

When calling the method, adding `expain: true` to the method call will, instead of the method's 
expected result, a string based on the template string provided in `explanation`. Using the example 
above:

### Calling the method without asking for the explanation

Simply returns the usual result:

```ruby
irb(main):001> Calculator.new.calculate(1, 2)
3
```

### Calling the method with `explain:` 

Returns the explanation message based on the template:

```ruby
irb(main):001> Calculator.new.calculate(1, 2, explain: true)
calculate adds two integers
x + y
1 + 2
```

### Calling the method with `explain_with_result`

Calls the method as usual, stores the result, and returns the explanation with the result (rendered through the template):

```ruby
irb(main):001> Calculator.new.calculate(1, 2, explain_with_result: true)
calculate adds two integers
x + y
1 + 2
Result => 3
```

## Template Context

The `explanation` decorator method will run your ERB template with a context containing:

- All positional or keyword arguments
- The method's `receiver` as `obj`.
  - Instance variables can be accessed with `obj.varname` (drop the `@`). This is less than ideal, I hope to figure out how to make these available as `@varname` the same as in the code.
  - Methods can be called with `obj.method` as usual
- Optionally, the result of the actual call as `result`
- The owning class as `source_class`
- The file location as `source_location`
