require_relative "incidence"

module Refraction
  extend Physics::Law

  include Incidence

  quantity :angle_of_refraction,               variable: :rr, within: Physics::A_RIGHT_ANGLE
  quantity :refractive_index_of_first_medium,  variable: :mu1
  quantity :refractive_index_of_second_medium, variable: :mu2

  equation(:snells_law) { mu1 * sin(i) == mu2 * sin(rr) }

  condition(:no_refracted_ray) { mu1 * sin(i) / mu2 > 1 }
end
