require_relative "../../light/reflection"
require_relative "../../light/refraction"
require_relative "../../light/media"
require_relative "../../light/picture"

ANGLE = (0.5.deg)..(89.5.deg)
FINELY = 0.01.deg

play_with Reflection, Refraction do
  title "Refraction"
  description "A ray crossing into another medium bends, and the two media together decide which way."

  input  :i,    ANGLE, step: FINELY, at: 30.deg, in: :degrees, as: "incidence"
  choose :from, MEDIA, at: "air",   as: "from"
  choose :into, MEDIA, at: "glass", as: "into"

  given(:mu21) { into / from }

  output :rr, in: :degrees
  output("bends") do
    turned = solve(:rr) - solve(:i)
    next "not at all" if turned.abs < 1e-6

    turned.negative? ? "toward the normal" : "away from the normal"
  end
  output :no_refracted_ray, in: :plain, alarm: true

  draw Light::Picture do
    media :from, :into
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :rl
    ray "refracted", crossing_at: :rr, angle: true, unless: :no_refracted_ray
    note "no refracted ray", when: :no_refracted_ray
  end
end
