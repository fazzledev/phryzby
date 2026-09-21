module Physics
  module Declarations
    include Quantities

    def self.extended(law) = law.forget

    def forget
      super
      equations.clear
      conditions.clear
      guards.clear
    end

    def equations = @equations ||= {}
    def conditions = @conditions ||= {}
    def guards = @guards ||= {}

    def absorb(other)
      super
      return unless other.respond_to?(:equations)

      equations.merge!(other.equations)
      conditions.merge!(other.conditions)
      guards.merge!(other.guards)
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
  end
end
