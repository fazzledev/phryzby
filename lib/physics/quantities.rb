module Physics
  module Quantities
    def variables = @variables ||= {}
    def domains = @domains ||= {}

    def variable(name, **options)
      variables[name] = name
      variables[options[:alias]] = name if options[:alias]
      domains[name] = options[:within] if options[:within]
    end

    def absorb(other)
      variables.merge!(other.variables)
      domains.merge!(other.domains)
    end

    def included(host) = host.absorb(self)
  end
end
