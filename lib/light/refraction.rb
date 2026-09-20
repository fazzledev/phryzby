require_relative "reflection"

module Refraction
  extend Physics::Law

  RIGHT_ANGLE = 0.0..(Math::PI / 2)
  INDEX = 1.0..4.0

  variable :angle_of_incidence,                alias: :i,   within: RIGHT_ANGLE
  variable :angle_of_refraction,               alias: :rr,  within: RIGHT_ANGLE
  variable :refractive_index_of_first_medium,  alias: :mu1, within: INDEX
  variable :refractive_index_of_second_medium, alias: :mu2, within: INDEX

  equation(:snells_law) { mu2 / mu1 == sin(i) / sin(rr) }

  condition(:total_internal_reflection) { sin(i) * mu1 / mu2 > 1 }
end

class Interface
  include Refraction
end
