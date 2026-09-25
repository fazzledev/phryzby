require_relative "../../flight/projectile"
require_relative "../../flight/gravity"
require_relative "../../flight/picture"

play_with Projectile do
  title "Projectile"
  question "Where does a thrown thing land?"
  description "Wherever the throw sent it. Nothing touches it after it leaves the hand, so the angle it left at, the speed it left at, and how hard the world pulls decide the whole flight."

  input :theta, default: 45.deg
  input :u, 5.0..25.0, in: :speed, default: 18.0

  input :world, GRAVITY, default: "earth"

  input(:g) { world }

  output :x, in: :metres
  output :h, in: :metres
  output :t, in: :seconds

  draw Flight::Picture, across: 65 do
    ground
    flight "thrown", leaving_at: :theta
    reach "range", :x
    apex "peak", :h
  end
end
