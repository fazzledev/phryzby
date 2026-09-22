require_relative "refraction"

module RefractiveIndex
  extend Physics::Law

  include Refraction

  quantity :refractive_index_of_first_medium,  variable: :mu1
  quantity :refractive_index_of_second_medium, variable: :mu2

  equation(:relative_index) { mu21 == mu2 / mu1 }
end
