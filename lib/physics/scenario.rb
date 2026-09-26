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

      # Which equation each answer came from. The solver takes one way of
      # several — it tries the equation with the fewest unknowns left and
      # stops at the first answer — so this is the way it went, not the only
      # way there was. An answer reached round a ring came by every equation
      # the ring was unrolled through.
      @worked = {}
    end

    attr_reader :worked

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

    def determine(key, range, pending, except: nil, ringed: true)
      candidates(key, except, pending).each do |name, equation|
        restore, taken = @env.dup, @worked.dup

        if supply(equation, key, pending, except)
          found = root_of(equation, key, range)
          if found
            @worked[key] = [ name ]
            return @env[key] = found
          end
        end

        @env.replace(restore)
        @worked.replace(taken)
      end

      if ringed && (answer = round_the_houses(key, range, except))
        found, through = answer
        @worked[key] = through
        return @env[key] = found
      end

      raise "no equation determines the #{key.to_s.tr("_", " ")} from what is known"
    end

    # Everything above works by putting a number in place of each unknown it
    # does not want, which cannot be done when the way to that number leads
    # back to the one being asked for. A ring of equations has no end to start
    # from and the search above gives up at it.
    #
    # It does not need the number, though. It needs the name gone — and an
    # equation with a bare name on one side says what that name stands for, so
    # the expression can go in its place. Do that until the only unknown left
    # is the one being asked for, and a ring has become a single equation the
    # ordinary solver can turn round.
    # Every equation is a place to start, not only the ones that name what is
    # being asked for: in a ring the equation holding the known value often
    # does not mention it at all, and only comes to once the names between
    # them have been written out.
    def round_the_houses(key, range, except)
      self.class.equations.each do |name, equation|
        next if name == except

        unrolled, through = unroll(equation, key)
        next unless unrolled

        found = root_of(unrolled, key, range)
        return [ found, [ name ] + through ] if found
      end

      nil
    end

    UNROLLING = 8

    # No equation may be put into itself, or into anything it has already been
    # put into: H == u_y ** 2 / (2 * g) with H replaced by what that same
    # equation says H is comes to nought equals nought, which every number
    # satisfies and none answers.
    def unroll(equation, key)
      spent = [ equation ]
      through = []

      UNROLLING.times do
        missing = equation.variables - @env.keys - [ key ]
        if missing.empty?
          return equation.variables.include?(key) ? [ equation, through ] : nil
        end

        name, said, from = standing_for(missing, spent)
        return nil unless name

        spent << from
        through << self.class.equations.key(from)
        equation = equation.instead(name, said)
      end

      nil
    end

    def standing_for(missing, spent)
      missing.each do |name|
        self.class.equations.each_value do |equation|
          next if spent.include?(equation)

          said = equation.defines
          return [ name, said.last, equation ] if said && said.first == name
        end
      end

      nil
    end

    # A guarded equation states a special case, so it is tried before the
    # general one it stands in for. Without that the answer would depend on
    # the order the laws happened to be included in.
    def candidates(key, except = nil, pending = [])
      applicable = self.class.equations.select do |name, equation|
        name != except && equation.variables.include?(key) && applies?(name, pending)
      end

      special, general = applicable.partition { |name, _| self.class.guards.key?(name) }
      nearest(special, key) + nearest(general, key)
    end

    # The one that asks for least first. Where two equations both reach what
    # is wanted, the one with fewer things still to work out is the more
    # direct statement of it — and the longer way round is often the worse
    # arithmetic as well: the time of flight is in the range equation, but
    # thrown straight up the range and the speed along the ground have both
    # gone to nothing and that equation can say nothing about anything.
    def nearest(equations, key)
      equations.sort_by { |_, equation| (equation.variables - @env.keys - [ key ]).size }
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

        # Not round the houses: that is for a question which has otherwise
        # failed outright. Reaching for it here would make more things
        # determinable part way down, and so change which equation a question
        # is answered from — including to one that is degenerate.
        determine(missing, nil, pending + [ missing ], except: except, ringed: false)
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
