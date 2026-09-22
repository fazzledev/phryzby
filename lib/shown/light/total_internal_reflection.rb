require_relative "../../light/reflection"
require_relative "../../light/total_internal_reflection"
require_relative "../../light/picture"

ANGLE = (0.5.deg)..(89.5.deg)
FINELY = 0.01.deg
INDEX = 1.0..2.5

Physics::Scenario.including(Reflection, TotalInternalReflection).showing do
  titled TotalInternalReflection
  called "Total internal reflection"
  about "a law that only sometimes holds"
  describes "Chapter 1.4 ran out of answers past the critical angle: every Fresnel equation needs a refracted angle and there is not one. This chapter states what happens instead — <code>r == 1</code> — and states it <em>conditionally</em>, so the solver reaches for it only in the regime where it is true. One equation, one <code>when:</code>, and the word <em>total</em> stops being a claim in prose."

  vary :i,   ANGLE, step: FINELY, at: 30.deg, in: :degrees, as: "incidence"
  vary :mu1, INDEX, step: 0.01, at: 1.5, as: "μ₁ first"
  vary :mu2, INDEX, step: 0.01, at: 1.0, as: "μ₂ second"

  show("critical angle") do
    next "none" unless self[:mu2] < self[:mu1]

    format("%.2f°", Physics::Scenario.including(Refraction)
      .new(mu1: self[:mu1], mu2: self[:mu2], rr: 90.deg).solve(:i).in_degrees)
  end
  show :no_refracted_ray, in: :plain, alarm: true
  show :r, in: :percent
  show("solved from") { satisfies?(:no_refracted_ray) ? ":everything_reflects" : ":unpolarised" }

  draws Light::Picture do
    media :mu1, :mu2
    ray "incident",  arriving_at: :i
    ray "reflected", leaving_at: :i, weight: :r
    ray "refracted", crossing_at: :rr, weight: -> { 1.0 - solve(:r) }, unless: :no_refracted_ray
    note "trapped — every ray turns back", when: :no_refracted_ray
  end
end
