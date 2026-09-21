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
    def quantities = []
    def to_s = @value.to_s
  end

  class Var < Expr
    attr_reader :name

    def initialize(name) = @name = name

    def evaluate(env)
      env.fetch(@name) { raise KeyError, "no value for #{@name}" }
    end

    def quantities = [ @name ]
    def to_s = @name.to_s
  end

  class BinOp < Expr
    def initialize(op, left, right)
      @op = op
      @left = Expr.wrap(left)
      @right = Expr.wrap(right)
    end

    def evaluate(env) = @left.evaluate(env).public_send(@op, @right.evaluate(env))
    def quantities = @left.quantities | @right.quantities
    def to_s = "(#{@left} #{@op} #{@right})"
  end

  class Fn < Expr
    def initialize(name, arg)
      @name = name
      @arg = Expr.wrap(arg)
    end

    def evaluate(env) = Math.public_send(@name, @arg.evaluate(env))
    def quantities = @arg.quantities
    def to_s = "#{@name}(#{@arg})"
  end
end
