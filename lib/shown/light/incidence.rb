require_relative "../../light/incidence"
require_relative "../../light/picture"

ANGLE = (0.5.deg)..(89.5.deg)
FINELY = 0.01.deg
INDEX = 1.0..2.5

Arriving = Physics::Scenario[Incidence].showing do
  titled Incidence

  vary :i, ANGLE, step: 0.1.deg, at: 30.deg, in: :degrees, as: "incidence"

  show :i, in: :degrees, as: "held"
  show("asked to solve it", alarm: true) do
    Physics::Scenario[Incidence].new.solve(:i)
  rescue RuntimeError => e
    e.message
  end

  draws Light::Picture do
    surface called: "surface"
    ray "incident", arriving_at: :i
  end
end
