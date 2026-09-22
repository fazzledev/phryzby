require_relative "../../light/reflection"
require_relative "../../light/picture"

play_with Reflection do
  title "Reflection"
  description "A ray striking a mirror leaves at the same angle it arrived at, on the other side of the normal."

  input :i, default: 30.deg

  output :rl

  draw Light::Picture do
    mirror
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :rl, angle: true
  end
end
