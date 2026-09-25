require "minitest/autorun"
require_relative "../chapters"

# The drawing is the chapter's own; the label placing under it is not, and
# that is the point of the chapter: two subjects, one engine, one way of
# putting words on a diagram.
class FlightPictureTest < Minitest::Test
  def drawn(**values) = THROWN.picture(THROWN.opening.merge(values), settled: {})

  def points(svg) = svg[/<path id="flight" d="M ([^"]+)"/, 1]
                       .split(" L ").map { |pair| pair.split(",").map(&:to_f) }

  def test_it_draws_an_arc_that_starts_and_ends_on_the_ground
    walked = points(drawn)

    assert_in_delta Flight::Picture::GROUND, walked.first[1], 0.01
    assert_in_delta Flight::Picture::GROUND, walked.last[1], 0.01
  end

  def test_the_arc_climbs_to_the_middle_and_falls_away_again
    climbed = points(drawn).map { |(_, y)| y }

    assert_equal climbed.each_index.min_by { |n| climbed[n] }, climbed.size / 2
  end

  # The frame is cut for the fastest throw the chapter allows, so a slower one
  # is visibly shorter rather than redrawn to fill the same space.
  def test_a_slower_throw_lands_nearer
    far = points(drawn(u: 25.0)).last[0]
    near = points(drawn(u: 10.0)).last[0]

    assert_operator near, :<, far
  end

  def test_nothing_it_draws_leaves_the_frame
    [ 5.0, 15.0, 25.0 ].each do |speed|
      [ 5.deg, 45.deg, 85.deg ].each do |turned|
        points(drawn(u: speed, theta: turned)).each do |(x, y)|
          assert_includes 0.0..Flight::Picture::WIDTH.to_f, x
          assert_includes 0.0..Flight::Picture::HEIGHT.to_f, y
        end
      end
    end
  end

  # The angle is swung about the hand and measured up off the ground, which
  # is not how an optics picture measures one — so the picture says which.
  def test_it_tells_the_page_where_its_angle_is_measured_from
    assert_includes drawn, %(data-drags="theta" data-at="20 172")
  end

  # The ball is in the air for exactly as long as the law says it is, so the
  # picture asks rather than picks.
  def test_the_ball_flies_for_the_time_of_flight
    seconds = THROWN.posing(**THROWN.opening).solve(:t)

    assert_includes drawn, %(dur="#{seconds.round(3)}s")
  end

  def test_a_throw_that_never_leaves_the_ground_has_no_ball_to_fly
    refute_includes drawn(theta: 0.0), "animateMotion"
  end

  def test_it_names_what_it_drew
    [ "ground", "thrown", "range", "peak" ].each { |called| assert_includes drawn, ">#{called}<" }
  end
end
