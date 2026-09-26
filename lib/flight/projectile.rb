require_relative "../physics"

# Throw something and let go of it. Nothing pushes it after that, so where it
# goes is settled the instant it leaves your hand — by how fast it left, the
# angle it left at, and how hard the world pulls down.
module Projectile
  extend Physics::Law

  quantity :speed,           variable: :u
  quantity :angle_of_throw,  variable: :theta_0, within: Physics::A_RIGHT_ANGLE
  quantity :gravity,         variable: :g

  # A throw at an angle is two throws at once: one along the ground, which
  # nothing interferes with, and one straight up, which gravity spends. Every
  # question below is really about one or the other.
  quantity :initial_velocity_across, variable: :u_x
  quantity :initial_velocity_up,     variable: :u_y

  equation(:initial_velocity_across) { u_x == u * cos(theta_0) }
  equation(:initial_velocity_up)     { u_y == u * sin(theta_0) }

  quantity :range,           variable: :R
  quantity :peak,            variable: :H
  quantity :time_of_flight,  variable: :T

  # How far it got is how fast it was going along the ground times how long it
  # was off it — and it is also the one a book prints, which is that with the
  # components written out and a double angle collected up. Both are true and
  # both are here, because which way round a law can be asked depends on how
  # it was written, and a reader should be able to see the two routes rather
  # than be handed whichever one happened to be chosen.
  # Four ways of saying the same thing, and the way from each to the next. The
  # first is what it means. Put the time of flight into it for the second, and
  # the components into that for the third, which leaves two sin theta cos
  # theta standing in the open. Between the third and the fourth there is
  # nothing left but the identity that collects it up.
  equation(:horizontal_range)          { R == u_x * T }
  equation(:range_by_the_components)   { R == 2 * u_x * u_y / g }
  equation(:range_written_out)         { R == 2 * u * sin(theta_0) * u * cos(theta_0) / g }
  equation(:range_by_the_double_angle) { R == u**2 * sin(2 * theta_0) / g }

  identity(:double_angle,
           reconciles: %i[range_written_out range_by_the_double_angle]) do
    sin(2 * theta_0) == 2 * sin(theta_0) * cos(theta_0)
  end
  equation(:maximum_height)   { H == u_y**2 / (2 * g) }
  equation(:time_of_flight)   { T == 2 * u_y / g }

  # And here is what the throw weighs, which is the one thing above that none
  # of it needed. A heavy stone and a light one thrown the same way land in the
  # same place at the same moment: gravity pulls harder on the heavy one and
  # the heavy one is harder to move, by exactly the same factor, and the two
  # cancel. The law can say what it weighs; nothing in the law ever asks.
  quantity :mass,   variable: :m
  quantity :weight, variable: :W

  equation(:weight) { W == m * g }
end
