require_relative "../../flight/projectile"
require_relative "../../flight/gravity"
require_relative "../../flight/picture"

# How far back to stand. A throw on the moon is thirty times the same throw on
# jupiter, and no one frame holds both.
IN_VIEW = { "65 m" => 65, "250 m" => 250, "1 km" => 1000, "6 km" => 6000 }.freeze

play_with Projectile do
  title "Projectile"
  question "Where does a thrown thing land?"
  description "Wherever the throw sent it. Nothing touches it after it leaves the hand, so the angle it left at, the speed it left at, and how hard the world pulls decide the whole flight."

  input :theta, default: 45.deg
  input :u, 5.0..100.0, in: :speed, default: 18.0

  input :world, GRAVITY, default: "earth"
  input :in_view, IN_VIEW

  input(:g) { world }

  input :k, 0.0..1.0, default: 0.5

  output :r, in: :metres
  output :h, in: :metres
  output :t, in: :seconds

  output :x,  in: :metres
  output :y,  in: :metres
  output :sx, in: :speed
  output :sy, in: :speed

  draw Flight::Picture do
    ground
    flight leaving_at: :theta
    now
    reach "range", :r
    apex "peak", :h
  end
end
