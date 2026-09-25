require_relative "../../light/reflection"
require_relative "../../light/picture"

play_with Reflection do
  title "Reflection"
  question "Where does a ray go when it hits a mirror?"
  description "Back out at the angle it came in at, on the other side of the normal, and all of it goes back."

  input :i, default: 30.deg

  output :r_l

  draw Light::Picture do
    mirror
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :r_l, angle: true
  end
end
