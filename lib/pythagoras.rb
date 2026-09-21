require_relative "physics"

module Pythagoras
  extend Physics::Law

  LENGTH = 0.0..20.0

  quantity :leg_a,      variable: :a, within: LENGTH
  quantity :leg_b,      variable: :b, within: LENGTH
  quantity :hypotenuse, variable: :c, within: LENGTH

  equation(:pythagoras) { c ** 2 == a ** 2 + b ** 2 }
end
