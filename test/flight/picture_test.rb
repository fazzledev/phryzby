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

  # Left to itself the motion runs at one speed along the arc. A thrown thing
  # does not: it is quickest leaving and landing, and at the top none of its
  # going is upward, so it is down to however fast it is crossing the ground.
  # The ratio of the two is 1 over cos of the angle it left at.
  def test_the_ball_is_slowest_at_the_top
    steps = paces(drawn)
    middle = steps[steps.size / 2]

    assert_operator middle, :<, steps.first
    assert_in_delta 1 / Math.cos(45.deg), steps.first / middle, 0.02
  end

  # Half the time gets it half the way along, whatever the angle: what it does
  # going up, it undoes coming down.
  def test_it_is_half_way_along_at_half_the_time
    [ 20.deg, 45.deg, 80.deg ].each do |turned|
      svg = drawn(theta: turned)
      clock = svg[/keyTimes="([^"]+)"/, 1].split(";").map(&:to_f)
      reached = svg[/keyPoints="([^"]+)"/, 1].split(";").map(&:to_f)

      assert_in_delta 0.5, clock[clock.size / 2], 1e-9
      assert_in_delta 0.5, reached[reached.size / 2], 1e-3
    end
  end

  def paces(svg)
    svg[/keyPoints="([^"]+)"/, 1].split(";").map(&:to_f).each_cons(2).map { |a, b| b - a }
  end

  # keyTimes and keyPoints together say where the ball is at every moment, so
  # they can be walked back the way a browser walks them: linearly along the
  # arc between one pair and the next. Drop the height that gives, twice
  # differenced, and what falls out is the gravity the scenario was handed —
  # which is the whole claim the animation is making.
  def test_the_height_it_is_drawn_at_falls_under_the_gravity_it_was_given
    THROWN.picture(THROWN.opening, settled: {}).then do |svg|
      posed = THROWN.posing(**THROWN.opening)
      flight = posed.solve(:t)
      up = flown(svg)

      # A second difference of the height, over a span the chord error is
      # small against: the acceleration, in metres, downward.
      inner = (1..3).map { |n| flight * n / 4 }
      found = inner.map do |tau|
        step = flight / 8
        (up.call(tau + step) - 2 * up.call(tau) + up.call(tau - step)) / step**2
      end

      found.each { |fell| assert_in_delta(-posed.solve(:g), fell, 0.1) }
    end
  end

  # The height the browser will put it at, read off the attributes alone.
  def flown(svg)
    walked = svg[/<path id="flight" d="M ([^"]+)"/, 1]
               .split(" L ").map { |pair| pair.split(",").map(&:to_f) }
    clock = svg[/keyTimes="([^"]+)"/, 1].split(";").map(&:to_f)
    reached = svg[/keyPoints="([^"]+)"/, 1].split(";").map(&:to_f)
    flight = THROWN.posing(**THROWN.opening).solve(:t)

    runs = walked.each_cons(2).map { |(from, to)| Math.hypot(to[0] - from[0], to[1] - from[1]) }
    gone = runs.each_with_object([ 0.0 ]) { |step, kept| kept << kept.last + step }
    scale = Flight::Picture::REACH / svg[/>(\d+) m of ground</, 1].to_f

    lambda do |tau|
      at = (tau / flight).clamp(0.0, 1.0)
      n = clock.each_cons(2).find_index { |one, other| at.between?(one, other) } || clock.size - 2
      part = (at - clock[n]) / (clock[n + 1] - clock[n])
      want = (reached[n] + part * (reached[n + 1] - reached[n])) * gone.last

      m = gone.each_cons(2).find_index { |one, other| want.between?(one, other) } || walked.size - 2
      part = (want - gone[m]) / (gone[m + 1] - gone[m])

      (Flight::Picture::GROUND - (walked[m][1] + part * (walked[m + 1][1] - walked[m][1]))) / scale
    end
  end

  def test_a_throw_that_never_leaves_the_ground_has_no_ball_to_fly
    refute_includes drawn(theta: 0.0), "animateMotion"
  end

  # The ground in view does not move, so a world that pulls less is a throw
  # that reaches further across the same picture, and hangs about longer
  # doing it. Were the frame cut to fit each throw, every world would look
  # alike and nothing the reader pressed would show.
  def test_the_same_throw_reaches_further_on_a_world_that_pulls_less
    seen = GRAVITY.keys.each_index.map do |n|
      svg = drawn(world: n)
      [ svg[/<path id="flight" d="M ([^"]+)"/, 1].split(" L ").last.split(",").first.to_f,
        svg[/dur="([\d.]+)s"/, 1].to_f, svg[/>(\d+) m of ground</, 1].to_i ]
    end

    assert_equal seen.map(&:first).sort.reverse, seen.map(&:first)
    assert_equal seen.map { |(_, flight, _)| flight }.sort.reverse,
                 seen.map { |(_, flight, _)| flight }
    assert_equal 1, seen.map(&:last).uniq.size
  end

  # And when it reaches past the edge, the picture says so rather than
  # marking a spot that is not in it.
  def test_a_throw_that_leaves_the_picture_is_not_marked_where_it_lands
    moon = drawn(world: GRAVITY.keys.index("moon"))

    assert_includes moon, ">range \u2192<"
    refute_includes moon, ">range<"
  end

  # Six times less pull, six times the ground and six times as long in the air.
  def test_the_moon_is_the_earth_divided_by_its_own_pull
    moon, earth = %w[moon earth].map { |world| drawn(world: GRAVITY.keys.index(world)) }
    seconds = ->(svg) { svg[/dur="([\d.]+)s"/, 1].to_f }

    assert_in_delta GRAVITY.fetch("earth") / GRAVITY.fetch("moon"),
                    seconds.call(moon) / seconds.call(earth), 1e-3
  end

  # There is one curve in the picture, so naming it says nothing the picture
  # did not. What gets named is what is measured off it.
  def test_it_does_not_name_the_only_curve_in_the_picture
    refute_includes drawn, ">thrown<"
  end

  def test_it_names_what_it_drew
    [ "range", "peak" ].each { |called| assert_includes drawn, ">#{called}<" }
    assert_match(/>\d+ m of ground</, drawn)
  end
end
