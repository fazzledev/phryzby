module Physics
  module Declarations
    def variables = @variables ||= {}
    def equations = @equations ||= {}
    def conditions = @conditions ||= {}
    def domains = @domains ||= {}

    def variable(name, **options)
      variables[name] = name
      variables[options[:alias]] = name if options[:alias]
      domains[name] = options[:within] if options[:within]
    end

    def equation(name, &block) = equations[name] = Scope.new(variables).instance_eval(&block)
    def condition(name, &block) = conditions[name] = Scope.new(variables).instance_eval(&block)

    def uses(source, *names)
      names.each do |name|
        key = source.variables.fetch(name)
        variables[name] = key
        variables[key] = key
        domains[key] = source.domains[key] if source.domains.key?(key)
      end
    end

    def absorb(other)
      variables.merge!(other.variables)
      equations.merge!(other.equations)
      conditions.merge!(other.conditions)
      domains.merge!(other.domains)
    end
  end

  module Law
    include Declarations

    def included(model) = model.absorb(self)
  end
end
