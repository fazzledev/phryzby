require_relative "optics"
require_relative "reflection"

module Refraction
  extend Physics::Law

  uses Optics, :i, :rr, :mu1, :mu2

  equation(:snells_law) { mu2 / mu1 == sin(i) / sin(rr) }

  condition(:total_internal_reflection) { sin(i) * mu1 / mu2 > 1 }
end

class Surface < Physics::Scenario
  include Reflection
  include Refraction

  FLAT_ALONG_THE_SURFACE = Math::PI / 2

  def self.between(first, second, **angles) = new(mu1: first, mu2: second, **angles)

  def angle_of_refraction = solve(:rr, guess: ANGLE_GUESS)

  def second_medium = solve(:mu2, guess: 1.0)

  def traps? = satisfies?(:total_internal_reflection)

  def critical_angle
    return nil unless self[:mu2] < self[:mu1]

    lying_flat.solve(:i, guess: 0.7)
  end

  private

  def lying_flat
    self.class.between(self[:mu1], self[:mu2], rr: FLAT_ALONG_THE_SURFACE)
  end
end
