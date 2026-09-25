require "minitest/autorun"
require_relative "../../lib/physics"

# The solver takes one unknown out of one equation at a time, which works
# however deep the chain runs — until the chain bends back on itself. Then
# there is no end to start from, and the way through is to stop asking for a
# number and ask for the name instead: an equation with a bare name on one
# side says what that name stands for, and can be written in its place.
class RingsTest < Minitest::Test
  module Ringed
    extend Physics::Law

    quantity :speed,          variable: :u
    quantity :angle,          variable: :theta, within: Physics::A_RIGHT_ANGLE
    quantity :gravity,        variable: :g
    quantity :speed_across,   variable: :u_x
    quantity :speed_up,       variable: :u_y
    quantity :time_of_flight, variable: :T
    quantity :range,          variable: :R

    equation(:across)   { u_x == u * cos(theta) }
    equation(:up)       { u_y == u * sin(theta) }
    equation(:how_long) { T == 2 * u_y / g }
    equation(:how_far)  { R == u_x * T }
  end

  RING = Physics::Scenario.including(Ringed)
  EARTH = 9.81

  # The range is three equations away from the angle, and both of the ways to
  # it lead back through the angle. Written out in full it is one equation
  # with one unknown, and the answer is the one the closed form gives.
  def test_it_answers_through_a_ring_of_equations
    asked = RING.new(u: 20.0, theta: 45.deg, g: EARTH).asking(:theta, R: 30.0)

    assert_in_delta Math.asin(30.0 * EARTH / 400.0) / 2, asked, 1e-6
    assert_in_delta 30.0, RING.new(u: 20.0, theta: asked, g: EARTH).solve(:R), 1e-6
  end

  def test_it_answers_for_anything_else_in_the_ring_too
    one = RING.new(u: 20.0, theta: 45.deg, g: EARTH)

    assert_in_delta 20.0, RING.new(g: EARTH, theta: 45.deg, R: 400.0 / EARTH).solve(:u), 1e-6
    assert_in_delta 20.0 * Math.sin(45.deg), one.asking(:u_y, R: 400.0 / EARTH), 1e-6
  end

  # Forwards it was never in doubt; the point is that it is the same number.
  def test_the_ring_says_what_the_closed_form_says
    (5..85).step(10) do |degrees|
      found = RING.new(u: 20.0, theta: degrees.deg, g: EARTH).solve(:R)

      assert_in_delta 400.0 * Math.sin(2 * degrees.deg) / EARTH, found, 1e-9
    end
  end

  # An equation put in place of itself says nought equals nought, which every
  # number satisfies and none answers.
  module Alone
    extend Physics::Law

    quantity :height,   variable: :h
    quantity :speed_up, variable: :u_y
    quantity :gravity,  variable: :g

    equation(:climbs) { h == u_y**2 / (2 * g) }
  end

  def test_nothing_is_written_in_place_of_itself
    assert_in_delta 10.0, Physics::Scenario.including(Alone)
                                           .new(h: 10.0, g: EARTH).solve(:u_y)**2 / (2 * EARTH),
                    1e-9
    assert_raises(RuntimeError) { Physics::Scenario.including(Alone).new(g: EARTH).solve(:u_y) }
  end

  # Only an equation with a bare name on one side says what a name stands for.
  # Snell says how four things hang together and singles out none of them, so
  # there is nothing in it to write anywhere.
  module Tangled
    extend Physics::Law

    quantity :one,   variable: :a
    quantity :other, variable: :b
    quantity :third, variable: :c

    equation(:hangs_together) { a * b == c * 2 }
  end

  def test_an_equation_that_defines_nothing_offers_nothing_to_write_out
    assert_nil Tangled.equations.fetch(:hangs_together).defines
    assert_equal [ :speed_across, ], [ Ringed.equations.fetch(:across).defines.first ]
  end
end
