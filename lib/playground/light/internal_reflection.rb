require_relative "../../light/reflection"
require_relative "../../light/refraction"
require_relative "../../light/refractive_media"
require_relative "../../light/picture"

play_with Reflection, Refraction do
  title "Internal reflection"
  description "A boundary is neither a mirror nor a window. One ray arrives and two leave: some of the light crosses, and some of it turns back."

  input :from, REFRACTIVE_MEDIA, default: "glass"
  input :into, REFRACTIVE_MEDIA

  input(:i)    { 20.deg }
  input(:mu21) { into / from }

  output("the one that turns back") do
    next "neither, the two media are alike" if (solve(:mu21) - 1).abs < 1e-9

    solve(:mu21) < 1 ? "internal, it stays in the denser medium" : "external"
  end
  output :no_refracted_ray, alarm: true

  draw Light::Picture do
    media :from, :into
    ray "incident",  arriving_at: :i
    ray "reflected", leaving_at:  :rl
    ray "refracted", crossing_at: :rr, unless: :no_refracted_ray
    note "all of it turns back", when: :no_refracted_ray
  end
end
