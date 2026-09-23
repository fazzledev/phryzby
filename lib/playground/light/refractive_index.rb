require_relative "../../light/reflection"
require_relative "../../light/refractive_index"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

INDEX = 1.0..4.0

play_with Reflection, RefractiveIndex do
  title "Refractive Index"
  question "Where does that one number come from?"
  description "From one number each. What a medium does to light is its own, and only the ratio of the two ever shows."

  input :mu1, INDEX, default: 1.33, marks: REFRACTIVE_MEDIA
  input :mu2, INDEX, default: 1.0, marks: REFRACTIVE_MEDIA

  input(:i) { 30.deg }

  output :mu21
  output("critical", in: :degrees) { asking(:i, rr: 90.deg) }
  output :rr
  output :no_refracted_ray, alarm: true

  draw Light::Picture, rising: true do
    media :mu1, :mu2
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :rl
    ray "refracted", crossing_at: :rr, angle: true, unless: :no_refracted_ray
    mark "critical", arriving_at: -> { asking(:i, rr: 90.deg) }
    note "all of it turns back", when: :no_refracted_ray
  end
end
