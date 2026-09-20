module Physics
  class Model
    extend Declarations

    class << self
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

    def solve(target, guess: 0.5, range: nil)
      key = self.class.variables.fetch(target)
      equation = equation_for(key)
      residual = ->(x) { equation.residual(@env.merge(key => x)) }
      within = range || self.class.domains[key] || Solver::DEFAULT_RANGE

      root = Solver.root(residual, guess: guess, within: within)
      raise "could not solve for #{target}" unless root

      @env[key] = root
    end

    private

    def equation_for(key)
      known = @env.keys
      candidate = self.class.equations.values.find do |equation|
        equation.variables.include?(key) && (equation.variables - known - [ key ]).empty?
      end
      candidate || raise("no equation determines #{key} from what is known")
    end
  end
end
