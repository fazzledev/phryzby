module Physics
  class Scenario
    extend Declarations

    class << self
      def [](*laws) = Class.new(self) { laws.each { |law| include law } }

      def inherited(subclass)
        super
        subclass.absorb(self)
      end
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

    def solve(target, range: nil)
      key = self.class.variables.fetch(target)

      @env.fetch(key) { determine(key, range, [ key ]) }
    end

    private

    def determine(key, range, pending)
      candidates(key).each do |equation|
        restore = @env.dup

        if supply(equation, key, pending)
          found = root_of(equation, key, range)
          return @env[key] = found if found
        end

        @env.replace(restore)
      end

      raise "no equation determines #{key} from what is known"
    end

    def candidates(key)
      self.class.equations.values.select { |equation| equation.variables.include?(key) }
    end

    def supply(equation, key, pending)
      (equation.variables - @env.keys - [ key ]).all? do |missing|
        next false if pending.include?(missing)

        determine(missing, nil, pending + [ missing ])
      rescue RuntimeError
        false
      end
    end

    def root_of(equation, key, range)
      residual = ->(x) { equation.residual(@env.merge(key => x)) }

      Solver.root(residual, within: range || self.class.domains[key] || Solver::DEFAULT_RANGE)
    end
  end
end
