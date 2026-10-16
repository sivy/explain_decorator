Rdoc on Github Pages: https://sivy.github.io/explain_decorator/README_md.html

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
expected result, a string based on the template string provided in `explanation`. In the example 
above:

```ruby
irb(main):001> Calculator.new.calculate(1, 2)
3
```

```ruby
irb(main):001> Calculator.new.calculate(1, 2, explain: true)
calculate adds two integers
x + y
1 + 2
```

```ruby
irb(main):001> Calculator.new.calculate(1, 2, explain_with_result: true)
calculate adds two integers
x + y
1 + 2
Result => 3
```