require_relative "incidence"

module Refraction
  extend Physics::Law

  include Incidence

  quantity :angle_of_refraction,       variable: :rr, within: Physics::A_RIGHT_ANGLE
  quantity :relative_refractive_index, variable: :mu21

  equation(:snells_law) { mu21 == sin(i) / sin(rr) }

  condition(:no_refracted_ray) { sin(i) / mu21 > 1 }
end
