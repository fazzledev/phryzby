module Physics
  module Quantities
    def variables = @variables ||= {}
    def domains = @domains ||= {}

    def variable(name, **options)
      variables[name] = name
      variables[options[:alias]] = name if options[:alias]
      domains[name] = options[:within] if options[:within]
    end

    def uses(source, *names)
      names.each do |name|
        key = source.variables.fetch(name)
        variables[name] = key
        variables[key] = key
        domains[key] = source.domains[key] if source.domains.key?(key)
      end
    end
  end
end
