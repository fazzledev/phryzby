module Physics
  module Quantities
    def quantities = @quantities ||= {}
    def domains = @domains ||= {}

    def quantity(name, **options)
      quantities[name] = name
      quantities[options[:variable]] = name if options[:variable]
      domains[name] = options[:within] if options[:within]
    end

    def absorb(other)
      quantities.merge!(other.quantities)
      domains.merge!(other.domains)
    end

    def included(host) = host.absorb(self)
  end
end
