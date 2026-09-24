require_relative "../../flight/projectile"
require_relative "../../flight/picture"

play_with Projectile do
  title "Projectile"
  question "Where does a thrown thing land?"
  description "Wherever the throw sent it. Nothing touches it after it leaves the hand, so the angle and the speed it left at decide the whole flight."

  input :theta, default: 45.deg
  input :u, 5.0..25.0, in: :speed, default: 18.0

  input(:g) { 9.81 }

  output :x, in: :metres
  output :h, in: :metres
  output :t, in: :seconds

  draw Flight::Picture do
    ground
    flight "thrown", leaving_at: :theta
    span "range", :x
    apex "peak", :h
  end
end
