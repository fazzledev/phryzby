require_relative "incidence"

module Refraction
  extend Physics::Law
  include Incidence

  quantity :angle_of_refraction, variable: :rr, within: Physics::A_RIGHT_ANGLE
  quantity :refractive_index_of_first_medium,  variable: :mu1
  quantity :refractive_index_of_second_medium, variable: :mu2
  quantity :relative_refractive_index,         variable: :mu21

  equation(:relative_index) { mu21 == mu2 / mu1 }
  equation(:snells_law)     { mu21 == sin(i) / sin(rr) }

  condition(:no_refracted_ray) { sin(i) / mu21 > 1 }
end
