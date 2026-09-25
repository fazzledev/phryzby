module Physics
  class Equation
    attr_reader :left, :right

    def initialize(left, right)
      @left = Expr.wrap(left)
      @right = Expr.wrap(right)
    end

    def residual(env) = @left.evaluate(env) - @right.evaluate(env)
    def variables = @left.variables | @right.variables
    def to_s = "#{@left} == #{@right}"

    def instead(name, expr) = Equation.new(@left.instead(name, expr), @right.instead(name, expr))

    # An equation with a bare name on one side says what that name stands for,
    # and so can be put in place of it. One with something on both sides —
    # mu_1 * sin(i) == mu_2 * sin(r_r) — says how four things hang together
    # and defines none of them.
    def defines
      return [ @left.name, @right ] if @left.is_a?(Var)
      return [ @right.name, @left ] if @right.is_a?(Var)

      nil
    end
  end

  class Comparison
    def initialize(op, left, right)
      @op = op
      @left = Expr.wrap(left)
      @right = Expr.wrap(right)
    end

    def satisfied?(env) = @left.evaluate(env).public_send(@op, @right.evaluate(env))
    def variables = @left.variables | @right.variables
    def to_s = "#{@left} #{@op} #{@right}"
  end
end
