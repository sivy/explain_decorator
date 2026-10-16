require_relative 'explain_decorator'

##
# Sample class using `ExplainDecorator`
class Calculator
  extend ExplainDecorator

  def initialize(rate)
    @rate = rate
  end

  # Calculate the tax on allowed_amount based on `@rate`
  def calculate_tax(allowed_amount)
    allowed_amount * @rate
  end

  # now wrap calculate_tax to support explanation
  explanation(:calculate_tax, <<~EXP
  Tax Calculation

  allowed_amount * @rate
  <%= allowed_amount %> * <%= obj.rate %>
  <% if result %>Result => <%= result %><% end %>

  (<%= source_location %> in <%= source_class %>)
  EXP
  )
end

c = Calculator.new(0.25)

puts c.calculate_tax(1000)

puts c.calculate_tax(1000, explain: true)

puts c.calculate_tax(1000, explain_with_result: true)
