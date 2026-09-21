require_relative "physics"

module Pythagoras
  extend Physics::Law

  LENGTH = 0.0..20.0

  variable :leg_a,      alias: :a, within: LENGTH
  variable :leg_b,      alias: :b, within: LENGTH
  variable :hypotenuse, alias: :c, within: LENGTH

  equation(:pythagoras) { c ** 2 == a ** 2 + b ** 2 }
end
