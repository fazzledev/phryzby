require "minitest/autorun"
require_relative "../../lib/shown/light/refraction"

class ShowingTest < Minitest::Test
  APART = 0.chr

  def shown = Physics.shown(Refraction)
  def showing = shown.showing_of
  def opening = showing.opening

  def test_a_scenario_is_still_a_scenario
    assert_in_delta 19.4712, shown.new(**opening).solve(:rr).in_degrees, 1e-3
  end

  def test_it_starts_where_it_was_told_to
    assert_in_delta 30.0, opening.fetch(:i).in_degrees, 1e-9
    assert_in_delta 1.5, opening.fetch(:mu2), 1e-9
  end

  def test_a_control_is_drawn_for_every_quantity_varied
    controls = showing.controls

    assert_equal 3, controls.scan(/data-vary=/).size
    assert_includes controls, 'data-vary="i"'
  end

  def test_a_reading_is_shown_in_the_unit_it_was_asked_for
    assert_includes showing.readouts(opening), "19.47°"
  end

  def test_a_reading_worked_out_by_hand_is_shown_too
    assert_includes showing.readouts(opening.merge(mu1: 1.5, mu2: 1.0)), "41.81°"
  end

  def test_a_reading_that_cannot_be_worked_out_says_so
    assert_includes showing.readouts(opening.merge(mu1: 1.5, mu2: 1.0, i: 60.deg)), "—"
  end

  def test_the_law_states_itself_and_the_showing_does_not
    assert_includes showing.law.to_html, "<h1>Refraction"
    refute_includes showing.to_html(opening), "<h1>"
  end

  def test_moving_a_control_gives_back_the_picture_the_numbers_and_the_labels
    picture, readouts, labels = showing.moved(opening.merge(i: 70.deg)).split(APART)

    assert_includes picture, "<svg"
    assert_includes readouts, "class=\"val\""
    assert_includes labels, "70.00°"
  end

  def test_a_quantity_is_written_the_way_the_law_writes_it
    assert_equal :mu1, showing.written_for(:refractive_index_of_first_medium)
    assert_equal :i, showing.written_for(:angle_of_incidence)
  end
end
