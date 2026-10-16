require_relative 'explain_decorator'

class Calculator
  extend ExplainDecorator

  def initialize(rate)
    if rate > 1
      rate = rate/100
    end

    @rate = rate
  end

  # calculate
  def calculate_tax(allowed_amount)
    allowed_amount * @rate
  end

  explanation(:calculate_tax, <<~EXP
  ------
  Tax Calculation

  amount * @rate
  <%= allowed_amount %> * <%= obj.rate %>
  <% if result %>=> <%= result %><% end %>

  (<%= source_location %>)
  ------
  EXP
  )
end

c = Calculator.new(0.25)

puts c.calculate_tax(1000)

puts c.calculate_tax(1000, explain: true)

puts c.calculate_tax(1000, explain_with_result: true)
