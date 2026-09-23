require_relative "../../light/reflection"
require_relative "../../light/picture"

play_with Reflection do
  title "Reflection"
  question "If nothing determines the angle a ray arrives at, what determines the one it leaves at?"
  description "The arriving angle does. Off a mirror a ray leaves at exactly the angle it came in at, on the other side of the normal, and all of it leaves."

  input :i, default: 30.deg

  output :rl

  draw Light::Picture do
    mirror
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :rl, angle: true
  end
end
