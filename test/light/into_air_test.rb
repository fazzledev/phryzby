require "minitest/autorun"
require_relative "../chapters"

# The chapter that walks down the media and watches the angle close.
class IntoAirTest < Minitest::Test
  def playing = INTO_AIR
  def opening = playing.opening
  READING = %r{<span>([^<]*)</span>.*?class="val">([^<]*)</span>}

  def says(**changes) = playing.readouts(opening.merge(**changes)).scan(READING).to_h
  def drawn(**changes) = playing.picture(opening.merge(**changes), settled: {})
  def rays(svg) = svg.scan(/<path class="head"/).size

  AIR = 0
  WATER = 1
  GLASS = 2
  DIAMOND = 3
  SILICON = 5

  # The medium is the only thing to move, and the angle it opens on is the
  # one the chapter before it named.
  def test_it_takes_up_where_the_chapter_before_it_left_off
    assert_equal [ :from ], opening.keys
    assert_equal WATER, opening.fetch(:from)
    assert_equal "48.75°", says.fetch("critical")
  end

  def test_the_denser_the_medium_the_sooner_it_stops_letting_light_out
    closing = [ WATER, GLASS, DIAMOND, SILICON ].map { |at| says(from: at).fetch("critical") }

    assert_equal [ "48.75°", "41.81°", "24.41°", "14.86°" ], closing
  end

  # Held at 30°, the first two still let light across and the rest do not, so
  # the ray goes while the reader walks the list.
  def test_and_the_ray_goes_while_the_reader_walks_the_list
    assert_equal 3, rays(drawn(from: GLASS))
    assert_equal 2, rays(drawn(from: DIAMOND))
    assert_includes drawn(from: DIAMOND), "all of it turns back"
  end

  # Air into air is no crossing at all: the ray goes straight on, and the
  # angle past which it would not is a right angle.
  def test_between_air_and_air_there_is_no_angle_it_cannot_cross_at
    assert_equal "90.00°", says(from: AIR).fetch("critical")
    assert_equal "30.00°", says(from: AIR).fetch("angle of refraction")
  end

  def test_the_second_medium_is_named_and_never_chosen
    named = drawn.scan(%r{<text[^>]*>([^<]+)</text>}).flatten

    assert_includes named, "air"
    assert_includes named, "water"
    assert_equal 1, playing.controls.scan(/name="from"/).size / REFRACTIVE_MEDIA.size
    refute_includes playing.controls, %(name="into")
  end
end
