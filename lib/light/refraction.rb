require_relative "optics"

module Refraction
  extend Physics::Law

  uses Optics, :i, :rr, :mu1, :mu2

  equation(:snells_law) { mu2 / mu1 == sin(i) / sin(rr) }

  condition(:total_internal_reflection) { sin(i) * mu1 / mu2 > 1 }
end

class Interface < Physics::Model
  include Refraction
end
