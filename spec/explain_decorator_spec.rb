require_relative '../explain_decorator'

RSpec.describe ExplainDecorator do

  class ExplainDecoratorTestSubject
    extend ExplainDecorator

    attr_reader :calls

    def initialize(a: nil)
      @a = a
      @calls = 0
    end

    def test_ary_args(x, y)
      x + y
    end
    explanation(:test_ary_args, <<~EXP
    (x + y)
    (<%= x %> + <%= y %>)
    EXP
    )

    def test_named_ary_args(x, y)
      x + y
    end
    explanation(:test_named_ary_args, <<~EXP
    (<%= x %> + <%= y %>) = <%= result %>
    EXP
    )

    def test_kw_args(x:, y:)
      x + y
    end
    explanation(:test_kw_args, <<~EXP
    (x + y)
    (<%= x %> + <%= y %>)
    EXP
    )

    def test_kw_args_list(x:)
      x
    end
    explanation(:test_kw_args_list, "<%= args.inspect %>")

    def test_kw_default(x:, y: 10)
      x * y
    end
    explanation(:test_kw_default, <<~EXP
    (<%= x %> * <%= y.inspect %>) = <%= result.inspect %>
    EXP
    )

    def test_mixed_args(x, y:)
      x - y
    end
    explanation(:test_mixed_args, <<~EXP
    (<%= x %> - <%= y %>) = <%= result.inspect %>
    EXP
    )

    def test_self_obj
      @a > 5
    end
    explanation(:test_self_obj, <<~EXP
    (@a > 5)
    (<%= obj.a %> > 5)
    EXP
    )

    def test_missing_ivar
      true
    end
    explanation(:test_missing_ivar, "<%= obj.not_set.inspect %>")

    def test_context
      nil
    end
    explanation(:test_context, "<%= source_class %>|<%= source_location %>")

    def test_tracked
      @calls += 1
    end
    explanation(:test_tracked, "tracked: <%= result.inspect %>")
  end

  let(:subject_class) { ExplainDecoratorTestSubject }
  let(:t) { subject_class.new(a: 3) }

  describe ".explanation" do
    it "keeps the original method available as <name>_old" do
      expect(t).to respond_to(:test_ary_args_old)
      expect(t.test_ary_args_old(4, 5)).to eq(9)
    end

    it "replaces the decorated method with a wrapper" do
      expect(subject_class.instance_method(:test_ary_args).source_location)
        .not_to eq(subject_class.instance_method(:test_ary_args_old).source_location)
    end
  end

  describe "calling without explain flags" do
    it "passes positional args through to the original method" do
      expect(t.test_ary_args(1, 2)).to eq(3)
    end

    it "passes keyword args through to the original method" do
      expect(t.test_kw_args(x: 1, y: 2)).to eq(3)
    end

    it "passes mixed positional and keyword args through" do
      expect(t.test_mixed_args(5, y: 2)).to eq(3)
    end

    it "respects keyword defaults of the original method" do
      expect(t.test_kw_default(x: 2)).to eq(20)
    end

    it "calls the original method when explain: false" do
      expect(t.test_ary_args(1, 2, explain: false)).to eq(3)
    end

    it "calls the original method when explain_with_result: false" do
      expect(t.test_ary_args(1, 2, explain_with_result: false)).to eq(3)
    end
  end

  describe "explain: true" do
    it "renders the template with array args" do
      expect(t.test_ary_args(1, 2, explain: true)).to eq(<<~EXP
      (x + y)
      (1 + 2)
      EXP
      )
    end

    it "exposes positional parameters by name" do
      expect(t.test_named_ary_args(1, 2, explain: true)).to eq("(1 + 2) = \n")
    end

    it "renders the template with keyword args" do
      expect(t.test_kw_args(x: 1, y: 2, explain: true)).to eq(<<~EXP
      (x + y)
      (1 + 2)
      EXP
      )
    end

    it "exposes keyword args to the template but leaves args empty" do
      expect(t.test_kw_args_list(x: 1, explain: true)).to eq("[]")
    end

    it "only exposes keyword args that were passed, not defaults" do
      expect(t.test_kw_default(x: 2, explain: true)).to eq("(2 * nil) = nil\n")
      expect(t.test_kw_default(x: 2, y: 3, explain: true)).to eq("(2 * 3) = nil\n")
    end

    it "exposes both positional and keyword args" do
      expect(t.test_mixed_args(5, y: 2, explain: true)).to eq("(5 - 2) = nil\n")
    end

    it "exposes instance variables via obj" do
      expect(t.test_self_obj).to eq(false)
      expect(t.test_self_obj(explain: true)).to eq(<<~EXP
      (@a > 5)
      (3 > 5)
      EXP
      )
    end

    it "returns nil for unset instance variables via obj" do
      expect(t.test_missing_ivar(explain: true)).to eq("nil")
    end

    it "exposes source_class and source_location" do
      location = subject_class.instance_method(:test_context_old).source_location.join(":")
      expect(t.test_context(explain: true)).to eq("#{subject_class}|#{location}")
    end

    it "does not call the original method" do
      expect(t.test_tracked(explain: true)).to eq("tracked: nil")
      expect(t.calls).to eq(0)
    end

    it "does not print to stdout" do
      expect { t.test_kw_args(x: 1, y: 2, explain: true) }.not_to output.to_stdout
    end
  end

  describe "explain_with_result: true" do
    it "renders the result of the original method" do
      expect(t.test_named_ary_args(1, 2, explain_with_result: true)).to eq("(1 + 2) = 3\n")
    end

    it "calls the original method exactly once" do
      expect(t.test_tracked(explain_with_result: true)).to eq("tracked: 1")
      expect(t.calls).to eq(1)
    end

    it "passes keyword args through and renders the result" do
      expect(t.test_kw_default(x: 2, explain_with_result: true)).to eq("(2 * nil) = 20\n")
      expect(t.test_kw_default(x: 2, y: 3, explain_with_result: true)).to eq("(2 * 3) = 6\n")
    end

    it "works with mixed positional and keyword args" do
      expect(t.test_mixed_args(5, y: 2, explain_with_result: true)).to eq("(5 - 2) = 3\n")
    end

    it "exposes instance variables via obj" do
      expect(t.test_self_obj(explain_with_result: true)).to eq(<<~EXP
      (@a > 5)
      (3 > 5)
      EXP
      )
    end

    it "does not print to stdout" do
      expect { t.test_ary_args(1, 2, explain_with_result: true) }.not_to output.to_stdout
    end
  end
end
