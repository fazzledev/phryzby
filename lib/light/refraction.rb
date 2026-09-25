require_relative "incidence"

module Refraction
  extend Physics::Law

  include Incidence

  quantity :angle_of_refraction,               variable: :r_r, within: Physics::A_RIGHT_ANGLE
  quantity :refractive_index_of_first_medium,  variable: :mu_1
  quantity :refractive_index_of_second_medium, variable: :mu_2

  equation(:snells_law) { mu_1 * sin(i) == mu_2 * sin(r_r) }

  condition(:no_refracted_ray) { mu_1 * sin(i) / mu_2 > 1 }
end
