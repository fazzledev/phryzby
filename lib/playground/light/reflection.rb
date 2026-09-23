require_relative "../../light/reflection"
require_relative "../../light/picture"

play_with Reflection do
  title "Reflection"
  question "A ray hits a mirror. Where does it go?"
  description "Back out at the angle it came in at, on the other side of the normal, and all of it goes back."

  input :i, default: 30.deg

  output :rl

  draw Light::Picture do
    mirror
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :rl, angle: true
  end
end
