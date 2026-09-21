module Physics
  module Quantities
    def variables = @variables ||= {}
    def domains = @domains ||= {}

    def variable(name, **options)
      variables[name] = name
      variables[options[:alias]] = name if options[:alias]
      domains[name] = options[:within] if options[:within]
    end
  end
end
