require_relative "../../flight/projectile"
require_relative "../../flight/gravity"
require_relative "../../flight/in_view"
require_relative "../../flight/picture"

play_with Projectile do
  title "Projectile"
  question "Where does a thrown thing land?"
  description "Wherever the throw sent it. Nothing touches it after it leaves the hand, so the angle it left at, the speed it left at, and how hard the world pulls decide the whole flight."

  input :theta_0, default: 45.deg, step: 5.deg
  input :u, 10.0..100.0, in: :"m/s", step: 10.0, default: 20.0

  input :world, GRAVITY, default: "earth"
  input :in_view, IN_VIEW

  input(:g) { world }

  output :R,   in: :m
  output :H,   in: :m
  output :T,   in: :s

  draw Flight::Picture do
    ground
    flight leaving_at: :theta_0
    reach "range", :R
    apex "peak", :H
  end
end
