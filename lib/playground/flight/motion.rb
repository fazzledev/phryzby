require_relative "../../flight/motion"
require_relative "../../flight/gravity"
require_relative "../../flight/in_view"
require_relative "../../flight/picture"

play_with Motion do
  title "Instants of a Projectile"
  question "And where is it while it is still going?"
  description "Somewhere along the same arc, at a moment you can name. Ask at half way and the answers are the range halved and the peak exactly — which is where the three the chapter before worked out came from."

  input(:g) { world }

  about "the throw, all of it" do
    input :theta_0, default: 45.deg, step: 5.deg
    input :u, 10.0..100.0, in: :"m/s", step: 10.0, default: 20.0

    input :world, GRAVITY, default: "earth"
    input :in_view, IN_VIEW

    output :R,   in: :m
    output :H,   in: :m
    output :T,   in: :s
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
