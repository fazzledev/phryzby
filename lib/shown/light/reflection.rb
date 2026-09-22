require_relative "../../light/reflection"
require_relative "../../light/picture"

ANGLE = (0.5.deg)..(89.5.deg)
FINELY = 0.01.deg
INDEX = 1.0..2.5

Physics::Scenario.including(Reflection).showing do
  called "Reflection"
  about "the angle out is the angle in"
  describes "The smallest law there is. Inside the equation block <code>i</code> and <code>rl</code> are not numbers — they are nodes in an expression tree, so <code>==</code> does not answer true or false, it builds an equation and hands it back."

  vary :i, ANGLE, step: 0.1.deg, at: 30.deg, in: :degrees, as: "incidence"

  show :i, in: :degrees
  show :rl, in: :degrees

  draws Light::Picture do
    surface called: "mirror"
    ray "incident",  arriving_at: :i
    ray "reflected", leaving_at:  :rl
  end
end
