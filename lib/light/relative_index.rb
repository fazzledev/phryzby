require_relative "refraction"

module RelativeIndex
  extend Physics::Law

  include Refraction

  quantity :relative_refractive_index, variable: :mu_21

  equation(:relative_index) { mu_21 == mu_2 / mu_1 }
end
