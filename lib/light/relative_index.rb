require_relative "refraction"

module RelativeIndex
  extend Physics::Law

  include Refraction

  quantity :relative_refractive_index, variable: :mu21

  equation(:relative_index) { mu21 == mu2 / mu1 }
end
