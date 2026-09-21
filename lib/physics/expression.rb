module Physics
  class Expr
    def +(other) = BinOp.new(:+, self, other)
    def -(other) = BinOp.new(:-, self, other)
    def *(other) = BinOp.new(:*, self, other)
    def /(other) = BinOp.new(:/, self, other)
    def **(other) = BinOp.new(:**, self, other)

    def ==(other) = Equation.new(self, other)

    def >(other)  = Comparison.new(:>, self, other)
    def <(other)  = Comparison.new(:<, self, other)
    def >=(other) = Comparison.new(:>=, self, other)
    def <=(other) = Comparison.new(:<=, self, other)

    def coerce(numeric) = [ Const.new(numeric), self ]

    def self.wrap(value) = value.is_a?(Expr) ? value : Const.new(value)
  end

  class Const < Expr
    def initialize(value) = @value = value
    def evaluate(_env) = @value
    def variables = []
    def to_s = @value.to_s
  end

  # Two names: the one it is looked up by, and the one it was written as.
  # Keeping both is what lets an equation print back the notation you chose.
  class Var < Expr
    attr_reader :name

    def initialize(name, written = name)
      @name = name
      @written = written
    end

    def evaluate(env)
      env.fetch(@name) { raise KeyError, "no value for #{@name}" }
    end

    def variables = [ @name ]
    def to_s = @written.to_s
  end

  class BinOp < Expr
    def initialize(op, left, right)
      @op = op
      @left = Expr.wrap(left)
      @right = Expr.wrap(right)
    end

    def evaluate(env) = @left.evaluate(env).public_send(@op, @right.evaluate(env))
    def variables = @left.variables | @right.variables
    def to_s = "(#{@left} #{@op} #{@right})"
  end

  class Fn < Expr
    def initialize(name, arg)
      @name = name
      @arg = Expr.wrap(arg)
    end

    def evaluate(env) = Math.public_send(@name, @arg.evaluate(env))
    def variables = @arg.variables
    def to_s = "#{@name}(#{@arg})"
  end
end
