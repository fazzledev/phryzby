module Physics
  module Declarations
    include Quantities

    def self.extended(law) = law.forget

    def forget
      super
      equations.clear
      conditions.clear
      guards.clear
      identities.clear
    end

    def equations = @equations ||= {}
    def conditions = @conditions ||= {}
    def guards = @guards ||= {}
    def identities = @identities ||= {}

    def absorb(other)
      super
      return unless other.respond_to?(:equations)

      equations.merge!(other.equations)
      conditions.merge!(other.conditions)
      guards.merge!(other.guards)
      identities.merge!(other.identities)
    end
  end

  module Law
    include Declarations

    def self.extended(law) = law.forget

    def equation(name, **options, &block)
      guards[name] = options[:when] if options[:when]
      equations[name] = Scope.new(quantities).instance_eval(&block)
    end

    def condition(name, &block) = conditions[name] = Scope.new(quantities).instance_eval(&block)

    # An identity is true for every value there is, so it settles nothing and
    # the solver never reaches for it — asking where it holds has no answer
    # when it holds everywhere. What it does is reconcile: two statements that
    # look different and are not, and this is why they are not.
    def identity(name, reconciles: [], &block)
      identities[name] = { holds: Scope.new(quantities).instance_eval(&block),
                           reconciles: reconciles }
    end
  end
end
