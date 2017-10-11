require 'test_helper'

class TokenCardTest < Test::Unit::TestCase
  def setup
    @visa = token_card('0995852004428291',   brand: 'visa')
  end

  def teardown
    @visa = nil
  end

  def test_constructor_should_properly_assign_values
    t = token_card

    assert_equal "8103301550498291", t.token
    assert_equal 9, t.month
    assert_equal Time.now.year + 1, t.year
    assert_equal "George McGeorgeson", t.name
    assert_equal "visa", t.brand
    assert_valid t
  end

  def test_new_token_card_should_not_be_valid
    t = TokenCard.new
    assert_not_valid t
  end

  def test_should_be_a_valid_visa_card
    assert_valid @visa
  end

  def test_cards_with_empty_names_should_not_be_valid
    @visa.first_name = ''
    @visa.last_name  = ''

    assert_not_valid @visa
  end

  def test_cards_with_empty_tokens_should_not_be_valid
    @visa.token = ''
    assert_not_valid @visa
  end

  def test_should_have_errors_with_invalid_card_brand
    @visa.brand = 'fred'

    errors = assert_not_valid @visa
    assert errors[:brand]
    assert_equal ["is invalid"], errors[:brand]
  end

  def test_should_be_invalid_when_brand_cannot_be_detected
    @visa.brand = nil
    errors = assert_not_valid @visa
    assert errors[:brand]
    assert_equal ['is required'], errors[:brand]
  end

  def test_should_require_a_valid_card_month
    @visa.month  = Time.now.utc.month
    @visa.year   = Time.now.utc.year

    assert_valid @visa
  end

  def test_should_not_be_valid_with_empty_month
    @visa.month = ''

    errors = assert_not_valid @visa
    assert_equal ['is required'], errors[:month]
  end

  def test_should_not_be_valid_for_edge_month_cases
    @visa.month = 13
    @visa.year = Time.now.year
    errors = assert_not_valid @visa
    assert errors[:month]

    @visa.month = 0
    @visa.year = Time.now.year
    errors = assert_not_valid @visa
    assert errors[:month]
  end

  def test_should_be_invalid_with_empty_year
    @visa.year = ''
    errors = assert_not_valid @visa
    assert_equal ['is required'], errors[:year]
  end

  def test_should_not_be_valid_for_edge_year_cases
    @visa.year  = Time.now.year - 1
    errors = assert_not_valid @visa
    assert errors[:year]
  end

  def test_should_be_a_valid_future_year
    @visa.year = Time.now.year + 1
    assert_valid @visa
  end

  def test_expired_card_should_have_one_error_on_year
    @visa.year = Time.now.year - 1
    errors = assert_not_valid(@visa)
    assert_not_nil errors[:year]
    assert_equal 1, errors[:year].size
    assert_match(/expired/, errors[:year].first)
  end

  def test_should_be_true_when_token_card_has_a_first_name
    t = TokenCard.new
    assert_false t.first_name?

    t = TokenCard.new(:first_name => 'James')
    assert t.first_name?
  end

  def test_should_be_true_when_credit_card_has_a_last_name
    t = TokenCard.new
    assert_false t.last_name?

    t = TokenCard.new(:last_name => 'Herdman')
    assert t.last_name?
  end

  def test_should_test_for_a_full_name
    t = TokenCard.new
    assert_false t.name?

    t = TokenCard.new(:first_name => 'James', :last_name => 'Herdman')
    assert t.name?
  end

  def test_should_assign_a_full_name
    t = TokenCard.new :name => "James Herdman"
    assert_equal "James", t.first_name
    assert_equal "Herdman", t.last_name

    t = TokenCard.new :name => "Rocket J. Squirrel"
    assert_equal "Rocket J.", t.first_name
    assert_equal "Squirrel", t.last_name

    t = TokenCard.new :name => "Twiggy"
    assert_equal "", t.first_name
    assert_equal "Twiggy", t.last_name
    assert_equal "Twiggy", t.name
  end

  def test_should_remove_trailing_whitespace_on_name
    t = TokenCard.new(:last_name => 'Herdman')
    assert_equal "Herdman", t.name

    t = TokenCard.new(:last_name => 'Herdman', first_name: '')
    assert_equal "Herdman", t.name
  end

  def test_should_remove_leading_whitespace_on_name
    t = TokenCard.new(:first_name => 'James')
    assert_equal "James", t.name

    t = TokenCard.new(:last_name => '', first_name: 'James')
    assert_equal "James", t.name
  end

  def test_month_and_year_are_immediately_converted_to_integers
    card = TokenCard.new

    card.month = "1"
    assert_equal 1, card.month
    card.year = "1"
    assert_equal 1, card.year

    card.month = ""
    assert_nil card.month
    card.year = ""
    assert_nil card.year

    card.month = nil
    assert_nil card.month
    card.year = nil
    assert_nil card.year
  end
end
