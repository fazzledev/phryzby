require_relative "../../light/refraction"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

play_with Refraction do
  title "Water to air"
  description "The same crossing taken the other way. It bends away from the normal now, and far enough round there is no way across at all."

  input :i, default: 30.deg
  input(:mu21) { REFRACTIVE_MEDIA.fetch("air") / REFRACTIVE_MEDIA.fetch("water") }

  output :rr
  output :no_refracted_ray, alarm: true

  draw Light::Picture do
    media "water", "air"
    ray "incident",  arriving_at: :i,  angle: true
    ray "refracted", crossing_at: :rr, angle: true, unless: :no_refracted_ray
    note "no refracted ray", when: :no_refracted_ray
  end
end
