module Physics
  class Scope < BasicObject
    def initialize(names) = @names = names

    def method_missing(name, *args)
      return Fn.new(name, args.first) if FUNCTIONS.include?(name)
      return Var.new(@names.fetch(name), name) if @names.key?(name)

      ::Kernel.raise ::NameError, "unknown name #{name} in a physics block"
    end

    def respond_to_missing?(name, _private = false)
      FUNCTIONS.include?(name) || @names.key?(name)
    end

    FUNCTIONS = %i[sin cos tan asin acos atan sqrt log exp].freeze
  end
end
