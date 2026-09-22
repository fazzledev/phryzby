require_relative "../../light/reflection"
require_relative "../../light/refraction"
require_relative "../../light/picture"

ANGLE = (0.5.deg)..(89.5.deg)
FINELY = 0.01.deg
INDEX = 1.0..2.5

Physics::Scenario[Reflection, Refraction].showing do
  titled Refraction

  vary :i,   ANGLE, step: FINELY, at: 30.deg, in: :degrees, as: "incidence"
  vary :mu1, INDEX, step: 0.01, at: 1.0, as: "μ₁ first"
  vary :mu2, INDEX, step: 0.01, at: 1.5, as: "μ₂ second"

  show :rr, in: :degrees
  show :rl, in: :degrees
  show("critical angle") do
    next "none" unless self[:mu2] < self[:mu1]

    format("%.2f°", Physics::Scenario[Refraction]
      .new(mu1: self[:mu1], mu2: self[:mu2], rr: 90.deg).solve(:i).in_degrees)
  end
  show :no_refracted_ray, in: :plain, alarm: true

  draws Light::Picture do
    media :mu1, :mu2
    ray "incident",  arriving_at: :i
    ray "reflected", leaving_at:  :rl
    ray "refracted", crossing_at: :rr, unless: :no_refracted_ray
    note "no refracted ray", when: :no_refracted_ray
  end
end
