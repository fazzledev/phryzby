module Physics
  module Quantities
    # Declaring a law again replaces it rather than adding to it, so a law
    # edited in a running VM says what it says now and not what it used to.
    def self.extended(law) = law.forget

    def forget
      quantities.clear
      domains.clear
      @called = @about = @describes = nil
    end

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
