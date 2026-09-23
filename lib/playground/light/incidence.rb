require_relative "../../light/incidence"
require_relative "../../light/picture"

play_with Incidence do
  title "Incidence"
  question "A ray meets a surface. What is there to measure?"
  description "The angle it makes with the normal, and nothing else. It is declared and never derived: no equation gives it, so asking for it is asking the book a question it cannot answer."

  input :i, default: 30.deg

  draw Light::Picture do
    surface
    ray "incident", arriving_at: :i, angle: true
  end
end
