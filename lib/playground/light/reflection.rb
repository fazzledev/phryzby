require_relative "../../light/reflection"
require_relative "../../light/picture"

ANGLE = (0.5.deg)..(89.5.deg)
FINELY = 0.01.deg
INDEX = 1.0..2.5

play_with Reflection do
  title "Reflection"
  description "A ray striking a mirror leaves at the same angle it arrived at, on the other side of the normal."

  input :i, ANGLE, step: 0.1.deg, at: 30.deg, in: :degrees, as: "incidence"

  output :i, in: :degrees
  output :rl, in: :degrees

  draws Light::Picture do
    mirror
    ray "incident",  arriving_at: :i, angle: true
    ray "reflected", leaving_at:  :rl, angle: true
  end
end
