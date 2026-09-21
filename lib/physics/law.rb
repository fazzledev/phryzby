module Physics
  module Declarations
    include Quantities

    def equations = @equations ||= {}
    def conditions = @conditions ||= {}
    def guards = @guards ||= {}

    def equation(name, **options, &block)
      guards[name] = options[:when] if options[:when]
      equations[name] = Scope.new(variables).instance_eval(&block)
    end

    def condition(name, &block) = conditions[name] = Scope.new(variables).instance_eval(&block)

    def absorb(other)
      variables.merge!(other.variables)
      equations.merge!(other.equations)
      conditions.merge!(other.conditions)
      guards.merge!(other.guards)
      domains.merge!(other.domains)
    end
  end

  module Law
    include Declarations

    def included(model) = model.absorb(self)
  end
end
