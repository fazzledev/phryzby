require_relative "../../light/incidence"
require_relative "../../light/picture"

play_with Incidence do
  title "Incidence"
  description "A ray arrives at a surface. The angle it makes with the normal is where every other law starts."

  input :i, default: 30.deg, as: "incidence"

  output :i, as: "held"
  output("asked to solve it", alarm: true) do
    Physics::Scenario.including(Incidence).new.solve(:i)
  rescue RuntimeError => e
    e.message
  end

  draw Light::Picture do
    surface
    ray "incident", arriving_at: :i, angle: true
  end
end
