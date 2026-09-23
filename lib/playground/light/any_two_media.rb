require_relative "../../light/refraction"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

play_with Refraction do
  title "Any Two Media"
  question "What do any two media do to a ray?"
  description "They bend it, and which way follows from which of them is the denser."

  input :from, REFRACTIVE_MEDIA
  input :into, REFRACTIVE_MEDIA, default: "glass"

  input(:i)    { 20.deg }
  input(:mu21) { into / from }

  output("bends") do
    turned = solve(:rr) - solve(:i)
    next "not at all" if turned.abs < 1e-6

    turned.negative? ? "toward the normal" : "away from the normal"
  end
  output :no_refracted_ray, alarm: true

  draw Light::Picture do
    media :from, :into
    ray "incident",  arriving_at: :i, extended: true
    ray "refracted", crossing_at: :rr, unless: :no_refracted_ray
    note "no refracted ray", when: :no_refracted_ray
  end
end
