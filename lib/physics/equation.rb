module Physics
  class Equation
    attr_reader :left, :right

    def initialize(left, right)
      @left = Expr.wrap(left)
      @right = Expr.wrap(right)
    end

    def residual(env) = @left.evaluate(env) - @right.evaluate(env)
    def quantities = @left.quantities | @right.quantities
    def to_s = "#{@left} == #{@right}"
  end

  class Comparison
    def initialize(op, left, right)
      @op = op
      @left = Expr.wrap(left)
      @right = Expr.wrap(right)
    end

    def satisfied?(env) = @left.evaluate(env).public_send(@op, @right.evaluate(env))
    def quantities = @left.quantities | @right.quantities
    def to_s = "#{@left} #{@op} #{@right}"
  end
end
