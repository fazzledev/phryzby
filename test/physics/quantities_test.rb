require "minitest/autorun"
require_relative "../../lib/physics"

class QuantitiesTest < Minitest::Test
  CATALOGUE = Module.new do
    extend Physics::Quantities

    variable :angle, alias: :a, within: 0.0..1.5
    variable :width, alias: :w, within: 0.0..9.0
    variable :depth, alias: :d
  end

  def test_uses_brings_the_alias_with_it
    borrower = catalogue { uses CATALOGUE, :a }

    assert_equal :angle, borrower.variables.fetch(:a)
    assert_equal :angle, borrower.variables.fetch(:angle)
  end

  def test_uses_brings_the_domain_with_it
    assert_equal 0.0..1.5, catalogue { uses CATALOGUE, :a }.domains.fetch(:angle)
  end

  def test_a_quantity_with_no_domain_declares_none
    refute catalogue { uses CATALOGUE, :d }.domains.key?(:depth)
  end

  def test_uses_takes_only_what_it_names
    borrower = catalogue { uses CATALOGUE, :a }

    refute borrower.variables.key?(:w)
    refute borrower.variables.key?(:width)
  end

  def test_a_quantity_that_is_not_in_the_catalogue_is_an_error
    assert_raises(KeyError) { catalogue { uses CATALOGUE, :nonesuch } }
  end

  def test_a_catalogue_states_no_equations
    refute_respond_to CATALOGUE, :equations
  end

  # It is not a law, so including it into a model is not a way to get its
  # quantities. A law has to name what it uses.
  def test_including_a_catalogue_into_a_model_absorbs_nothing
    model = Class.new(Physics::Scenario) { include CATALOGUE }

    assert_empty model.variables
  end

  private

  def catalogue(&declarations)
    Module.new do
      extend Physics::Quantities
      instance_eval(&declarations)
    end
  end
end
