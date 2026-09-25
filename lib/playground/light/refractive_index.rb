require_relative "../../light/reflection"
require_relative "../../light/refraction"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

INDEX = 1.0..4.0

play_with Reflection, Refraction do
  title "Refractive Index"
  question "Where does the bending come from?"
  description "From one number each. Every medium has its own, the law asks for both, and everything the last five chapters held fixed was a pair of them."

  input :mu_1, INDEX, default: 1.33, marks: REFRACTIVE_MEDIA
  input :mu_2, INDEX, default: 1.0, marks: REFRACTIVE_MEDIA

  input(:i) { 30.deg }

  output("critical", in: :deg) { asking(:i, r_r: 90.deg) }
  output :r_r
  output :no_refracted_ray, alarm: true

  draw Light::Picture, rising: true do
    media :mu_1, :mu_2
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :r_l
    ray "refracted", crossing_at: :r_r, angle: true, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, r_r: 90.deg) }
    note "all of it turns back", when: :no_refracted_ray
  end
end
