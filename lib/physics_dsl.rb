# A small declarative layer for writing physics as Ruby.
#
# The point is that a law should read the way it is written on a blackboard, and
# still be executable. So the variables inside an `equation` block are not
# numbers, they are expression nodes: `==` on them builds an equation rather
# than answering true or false, and the solver works on the residual afterwards.
#
#   ruby test/pythagoras_test.rb

module Physics
  # --- expression tree -------------------------------------------------------
  #
  # Every operator returns another node, so a block like
  #   { mu2 / mu1 == sin(i) / sin(rr) }
  # evaluates to an Equation instead of a boolean.

  class Expr
    def +(other) = BinOp.new(:+, self, other)
    def -(other) = BinOp.new(:-, self, other)
    def *(other) = BinOp.new(:*, self, other)
    def /(other) = BinOp.new(:/, self, other)
    def **(other) = BinOp.new(:**, self, other)

    # Deliberately not object equality: inside a DSL block this is how a law
    # gets stated. Nodes are never used as hash keys, so nothing depends on it.
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

  class Var < Expr
    attr_reader :name

    def initialize(name) = @name = name

    def evaluate(env)
      env.fetch(@name) { raise KeyError, "no value for #{@name}" }
    end

    def variables = [ @name ]
    def to_s = @name.to_s
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

  # --- statements ------------------------------------------------------------

  class Equation
    attr_reader :left, :right

    def initialize(left, right)
      @left = Expr.wrap(left)
      @right = Expr.wrap(right)
    end

    # Zero when the law holds. Everything the solver does is find a root of this.
    def residual(env) = @left.evaluate(env) - @right.evaluate(env)
    def variables = @left.variables | @right.variables
    def to_s = "#{@left} == #{@right}"
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

  # --- the context a declaration block runs in -------------------------------

  class Scope < BasicObject
    def initialize(names) = @names = names

    def method_missing(name, *args)
      return Fn.new(name, args.first) if FUNCTIONS.include?(name)
      return Var.new(@names.fetch(name)) if @names.key?(name)

      ::Kernel.raise ::NameError, "unknown name #{name} in a physics block"
    end

    def respond_to_missing?(name, _private = false)
      FUNCTIONS.include?(name) || @names.key?(name)
    end

    FUNCTIONS = %i[sin cos tan asin acos atan sqrt log exp].freeze
  end

  # --- the model -------------------------------------------------------------

  class Model
    class << self
      def variables = @variables ||= {}
      def equations = @equations ||= {}
      def conditions = @conditions ||= {}
      def domains = @domains ||= {}

      def inherited(subclass)
        super
        subclass.instance_variable_set(:@variables, variables.dup)
        subclass.instance_variable_set(:@equations, equations.dup)
        subclass.instance_variable_set(:@conditions, conditions.dup)
        subclass.instance_variable_set(:@domains, domains.dup)
      end

      # `alias:` is the symbol a physicist would actually write on the board.
      # `within:` is the branch the quantity physically lives on — a refracted
      # angle is between zero and a right angle, a reflectance is a fraction.
      # Without it the solver is free to return any root of a periodic law.
      def variable(name, **options)
        variables[name] = name
        variables[options[:alias]] = name if options[:alias]
        domains[name] = options[:within] if options[:within]
      end

      def equation(name, &block) = equations[name] = Scope.new(variables).instance_eval(&block)
      def condition(name, &block) = conditions[name] = Scope.new(variables).instance_eval(&block)
    end

    def initialize(**values)
      @env = {}
      values.each { |key, value| @env[self.class.variables.fetch(key)] = value }
    end

    def [](name) = @env[self.class.variables.fetch(name)]

    def holds?(name, tolerance: 1e-9)
      self.class.equations.fetch(name).residual(@env).abs < tolerance
    end

    def satisfies?(name) = self.class.conditions.fetch(name).satisfied?(@env)

    # Solve one unknown from whichever equation mentions it and nothing else
    # unknown. Newton first, then a bracketed bisection when Newton wanders —
    # and a root outside the variable's declared branch counts as wandering.
    def solve(target, guess: 0.5, range: nil)
      key = self.class.variables.fetch(target)
      range ||= self.class.domains[key] || (-10.0..10.0)
      equation = equation_for(key)
      residual = ->(x) { equation.residual(@env.merge(key => x)) }

      root = newton(residual, guess)
      root = nil unless root && range.cover?(root)
      root ||= bisect(residual, range)
      raise "could not solve for #{target}" unless root

      @env[key] = root
    end

    private

    def equation_for(key)
      known = @env.keys
      candidate = self.class.equations.values.find do |eq|
        eq.variables.include?(key) && (eq.variables - known - [ key ]).empty?
      end
      candidate || raise("no equation determines #{key} from what is known")
    end

    def newton(residual, guess, steps: 50, tolerance: 1e-12)
      x = guess
      steps.times do
        fx = residual.call(x)
        return x if fx.abs < tolerance

        slope = (residual.call(x + 1e-7) - fx) / 1e-7
        return nil if slope.abs < 1e-14

        x -= fx / slope
        return nil unless x.finite?
      end
      residual.call(x).abs < 1e-6 ? x : nil
    rescue Math::DomainError
      nil
    end

    def bisect(residual, range, steps: 200)
      lo, hi = range.begin, range.end
      scan = lo.step(by: (hi - lo) / 1000.0, to: hi).each_cons(2).find do |a, b|
        fa = safe(residual, a)
        fb = safe(residual, b)
        fa && fb && fa * fb <= 0
      end
      return nil unless scan

      lo, hi = scan
      steps.times do
        mid = (lo + hi) / 2.0
        break if (hi - lo).abs < 1e-12

        safe(residual, lo) * safe(residual, mid) <= 0 ? hi = mid : lo = mid
      end
      (lo + hi) / 2.0
    end

    def safe(residual, x)
      value = residual.call(x)
      value.finite? ? value : nil
    rescue Math::DomainError
      nil
    end
  end
end

class Numeric
  def deg = self * Math::PI / 180.0
  def in_degrees = self * 180.0 / Math::PI
end
