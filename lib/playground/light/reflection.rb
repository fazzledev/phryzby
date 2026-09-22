require_relative "../../light/reflection"
require_relative "../../light/picture"

ANGLE = (0.5.deg)..(89.5.deg)

play_with Reflection do
  title "Reflection"
  description "A ray striking a mirror leaves at the same angle it arrived at, on the other side of the normal."

  input :i, ANGLE, default: 30.deg, as: "incidence"

  output :i
  output :rl

  draw Light::Picture do
    mirror
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :rl, angle: true
  end
end
