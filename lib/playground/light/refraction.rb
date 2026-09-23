require_relative "../../light/refraction"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

play_with Refraction do
  title "Refraction: Air to Water"
  question "A mirror sends it all back. What becomes of a ray at a surface it can go through?"
  description "It crosses, and it bends toward the normal doing so. The two angles are neither equal nor proportional; what they hold to is a ratio of their sines."

  input :i, default: 60.deg
  input(:mu21) { REFRACTIVE_MEDIA.fetch("water") / REFRACTIVE_MEDIA.fetch("air") }

  output :rr

  draw Light::Picture do
    media "air", "water"
    ray "incident",  arriving_at: :i,  angle: true, extended: true
    ray "refracted", crossing_at: :rr, angle: true
  end
end
