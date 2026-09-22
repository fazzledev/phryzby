module Physics
  class Scenario
    extend Declarations

    class << self
      # The same verb a law uses to take up another. Whatever declares is
      # absorbed when it is included, and it makes no difference whether the
      # thing including it is a law or the scenario being solved.
      def including(*laws) = Class.new(self) { laws.each { |law| include law } }

      def inherited(subclass)
        super
        subclass.absorb(self)
      end
    end

    def initialize(**values)
      @env = {}
      values.each { |key, value| @env[self.class.quantities.fetch(key)] = value }

      # What the situation was posed with, as against what solving it has
      # since worked out.
      @given = @env.keys.freeze
    end

    def as_posed = @env.slice(*@given)

    def [](name) = @env[self.class.quantities.fetch(name)]
    def known = @env.dup

    # Anything the equation mentions and does not yet know is worked out
    # first — but never from the equation being checked, or it would make
    # itself true. What still cannot be known is left to name itself.
    def holds?(name, tolerance: 1e-9)
      equation = self.class.equations.fetch(name)

      (equation.variables - @env.keys).each do |key|
        determine(key, nil, [ key ], except: name)
      rescue RuntimeError
        nil
      end

      equation.residual(@env).abs < tolerance
    end

    # Like solve, a condition is asked rather than looked up: whatever it
    # mentions and does not yet know, it works out first.
    def satisfies?(name)
      condition = self.class.conditions.fetch(name)
      condition.variables.each { |key| solve(key) unless @env.key?(key) }

      condition.satisfied?(@env)
    end

    def solve(target, range: nil)
      key = self.class.quantities.fetch(target)

      @env.fetch(key) { determine(key, range, [ key ]) }
    end

    private

    def determine(key, range, pending, except: nil)
      candidates(key, except, pending).each do |equation|
        restore = @env.dup

        if supply(equation, key, pending, except)
          found = root_of(equation, key, range)
          return @env[key] = found if found
        end

        @env.replace(restore)
      end

      raise "no equation determines the #{key.to_s.tr("_", " ")} from what is known"
    end

    # A guarded equation states a special case, so it is tried before the
    # general one it stands in for. Without that the answer would depend on
    # the order the laws happened to be included in.
    def candidates(key, except = nil, pending = [])
      applicable = self.class.equations.select do |name, equation|
        name != except && equation.variables.include?(key) && applies?(name, pending)
      end

      special, general = applicable.partition { |name, _| self.class.guards.key?(name) }
      (special + general).map(&:last)
    end

    # A guard may work out what it needs — its condition can mention a quantity
    # nobody gave, as total internal reflection mentions the relative index.
    # What it must not work out is anything already being solved for: whether
    # an equation applies is asked in the middle of solving, and the two would
    # send each other round for ever.
    def applies?(name, pending = [])
      guard = self.class.guards[name]
      return true unless guard

      condition = self.class.conditions.fetch(guard)
      (condition.variables - @env.keys).each do |key|
        return false if pending.include?(key)

        determine(key, nil, pending + [ key ])
      end

      condition.satisfied?(@env)
    rescue KeyError, RuntimeError
      false
    end

    def supply(equation, key, pending, except = nil)
      (equation.variables - @env.keys - [ key ]).all? do |missing|
        next false if pending.include?(missing)

        determine(missing, nil, pending + [ missing ], except: except)
      rescue RuntimeError
        false
      end
    end

    def root_of(equation, key, range)
      residual = ->(x) { equation.residual(@env.merge(key => x)) }

      Solver.root(residual, within: range || self.class.domains[key])
    end
  end
end
