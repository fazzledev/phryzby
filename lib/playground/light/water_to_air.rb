require_relative "../../light/refraction"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

play_with Refraction do
  title "Refraction: Water to Air"
  question "Which way does it bend coming out of water?"
  description "It bends away from the normal instead, and far enough round there is no way across at all."

  input :i, default: 45.deg
  input(:mu21) { REFRACTIVE_MEDIA.fetch("air") / REFRACTIVE_MEDIA.fetch("water") }

  output :rr
  output :no_refracted_ray, alarm: true

  draw Light::Picture, rising: true do
    media "water", "air"
    ray "incident",  arriving_at: :i,  angle: true, extended: true
    ray "refracted", crossing_at: :rr, angle: true, unless: :no_refracted_ray
    note "no refracted ray", when: :no_refracted_ray
  end
end
