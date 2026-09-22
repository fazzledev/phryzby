require_relative "../../light/incidence"
require_relative "../../light/picture"

ANGLE = (0.5.deg)..(89.5.deg)
FINELY = 0.01.deg
INDEX = 1.0..2.5

Physics::Scenario.including(Incidence).showing do
  states Incidence
  called "Incidence"
  about "a quantity, and no law at all"
  describes "A ray arrives at a surface at some angle. That is the whole chapter: one quantity, its full name, the short name the equations will use, and the branch it lives on. There is no equation here, so there is nothing to solve — and that turns out to be the clearest way to see what the rest of the engine is doing."

  vary :i, ANGLE, step: 0.1.deg, at: 30.deg, in: :degrees, as: "incidence"

  show :i, in: :degrees, as: "held"
  show("asked to solve it", alarm: true) do
    Physics::Scenario.including(Incidence).new.solve(:i)
  rescue RuntimeError => e
    e.message
  end

  draws Light::Picture do
    surface called: "surface"
    ray "incident", arriving_at: :i
  end
end
