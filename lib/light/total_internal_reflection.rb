require_relative "reflectance"

module TotalInternalReflection
  extend Physics::Law

  include Reflectance

  equation(:everything_reflects, when: :no_refracted_ray) { r == 1 }
end
