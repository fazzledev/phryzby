require_relative "../physics"

module Refraction
  extend Physics::Law

  variable :angle_of_incidence,  alias: :i,  within: Physics::A_RIGHT_ANGLE
  variable :angle_of_refraction, alias: :rr, within: Physics::A_RIGHT_ANGLE
  variable :refractive_index_of_first_medium,  alias: :mu1
  variable :refractive_index_of_second_medium, alias: :mu2

  equation(:snells_law) { mu2 / mu1 == sin(i) / sin(rr) }

  condition(:total_internal_reflection) { sin(i) * mu1 / mu2 > 1 }
end
