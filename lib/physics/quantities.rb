module Physics
  module Quantities
    # Declaring a law again replaces it rather than adding to it, so a law
    # edited in a running VM says what it says now and not what it used to.
    def self.extended(law) = law.forget

    def forget
      quantities.clear
      domains.clear
      capitals.each { |written| remove_const(written) if const_defined?(written, false) }
      capitals.clear
    end

    def quantities = @quantities ||= {}
    def domains = @domains ||= {}
    def capitals = @capitals ||= []

    def quantity(name, **options)
      quantities[name] = name
      quantities[options[:variable]] = name if options[:variable]
      domains[name] = options[:within] if options[:within]
      capitalised(options[:variable], name)
    end

    # G and g are two different constants and differ only in case, so a law
    # has to be able to write both. An equation is written inside the law it
    # belongs to, and Ruby reads a bare capital there as a constant rather
    # than sending it to the scope every other name goes through — so a
    # quantity written with a capital is made one, standing for exactly what
    # the scope would have handed back.
    #
    # It is put away again by forget, like everything else a law declared, so
    # a law edited to drop the quantity drops the constant with it.
    def capitalised(written, name)
      return unless written && written.to_s.match?(/\A[A-Z]/)

      remove_const(written) if const_defined?(written, false)
      const_set(written, Var.new(name, written))
      capitals << written
    end

    def absorb(other)
      quantities.merge!(other.quantities)
      domains.merge!(other.domains)
    end

    def included(host) = host.absorb(self)
  end
end
