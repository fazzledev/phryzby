require_relative "../../light/refraction"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

play_with Refraction do
  title "Refraction: Air to Water"
  question "Where does a ray go when it hits water?"
  description "It goes through, and bends toward the normal doing so. The two angles are neither equal nor proportional: what each medium does to the sine of its own angle, the other undoes."

  input :i, default: 60.deg
  input(:mu_1) { REFRACTIVE_MEDIA.fetch("air") }
  input(:mu_2) { REFRACTIVE_MEDIA.fetch("water") }

  output :r_r

  draw Light::Picture do
    media "air", "water"
    ray "incident",  arriving_at: :i,  angle: true, extended: true
    ray "refracted", crossing_at: :r_r, angle: true
  end
end
