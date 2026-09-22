require_relative "../../light/refraction"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

play_with Refraction do
  title "Refraction: Air to Water"
  description "Crossing from air into water a ray bends toward the normal. The two angles are neither equal nor proportional; what they hold to is a ratio of their sines."

  input :i, default: 30.deg
  input(:mu21) { REFRACTIVE_MEDIA.fetch("water") / REFRACTIVE_MEDIA.fetch("air") }

  output :rr

  draw Light::Picture do
    media "air", "water"
    ray "incident",  arriving_at: :i,  angle: true
    ray "refracted", crossing_at: :rr, angle: true
  end
end
