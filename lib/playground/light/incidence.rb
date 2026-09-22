require_relative "../../light/incidence"
require_relative "../../light/picture"

ANGLE = (0.5.deg)..(89.5.deg)

play_with Incidence do
  title "Incidence"
  description "A ray arrives at a surface. The angle it makes with the normal is where every other law starts."

  input :i, ANGLE, step: 0.1.deg, at: 30.deg, in: :degrees, as: "incidence"

  output :i, in: :degrees, as: "held"
  output("asked to solve it", alarm: true) do
    Physics::Scenario.including(Incidence).new.solve(:i)
  rescue RuntimeError => e
    e.message
  end

  draw Light::Picture do
    surface called: "surface"
    ray "incident", arriving_at: :i
  end
end
