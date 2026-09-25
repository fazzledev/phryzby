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

  input(:g) { world }

  about "the throw, all of it" do
    input :theta_0, default: 45.deg
    input :u, 5.0..100.0, in: :"m/s", default: 18.0

    input :world, GRAVITY, default: "earth"
    input :in_view, IN_VIEW

    output :R,   in: :m
    output :H,   in: :m
    output :T, in: :s
  end

  about "one moment of it" do
    input :k, 0.0..1.0, default: 0.5

    output :t,   in: :s
    output :x,   in: :m
    output :y,   in: :m
    output :v_x, in: :"m/s"
    output :v_y, in: :"m/s"
    output :theta, in: :deg
  end

  draw Flight::Picture do
    ground
    flight leaving_at: :theta_0
    now
    reach "range", :R
    apex "peak", :H
  end
end
