# frozen_string_literal: true

require_relative 'deck'

# a Hand represents a player's hand.
# => A player can bet on a hand; when he declares "split",
# => he essentially has two hands.
class Hand
  attr_accessor :cards, :bet, :finished_playing, :splittable, :can_have_blackjack

  # by default, we can split a hand
  def initialize(splittable: true)
    self.cards = []
    self.bet = 0
    self.finished_playing = false
    self.splittable = splittable
    self.can_have_blackjack = true
  end

  # signify that this hand has finished play
  def end_play!
    self.finished_playing = true
  end

  # double the bet.  Called in player's double down option
  def double_bet!
    self.bet = bet * 2
  end

  # assuming that we're splittable, return one of the two cards
  def split!
    self.can_have_blackjack = false
    new_hand = Hand.new
    new_hand.cards << cards.pop
    new_hand.bet = bet
    new_hand.can_have_blackjack = false
    new_hand
  end

  # can we split the hand, assuming sufficient funds?
  def can_split?
    cards.length == 2 and
      cards[0].value == cards[1].value and
      splittable
  end

  # has the hand busted?
  def is_busted?
    value? > 21
  end

  # is this hand a blackjack?
  def is_blackjack?
    can_have_blackjack and cards.length == 2 and value? == 21
  end

  # вычислить ценность руки
  # значение будет выбирать значения для тузов (1 или 11)
  # сначала пытаясь максимизировать общую сумму <= 21,
  # и, если это невозможно, вернуть минимальную общую сумму > 21
  def value?
    value = 0
    num_aces = 0

    # add up maximum values
    cards.each do |card|
      num_aces += 1 if card.rank == 'Ace'
      value += card.value
    end

    # subtract 10 for as many aces we have
    # to get the result just under 21
    counter = 0
    while value > 21 && counter < num_aces
      counter += 1
      value -= 10
    end
    value
  end

  # turns the hand to string.
  # => show_bet = true will show the bet value of the hand
  # => only_first_card = true will show only the first card
  # => show_value will print the value of the hand (if not busted)
  def to_string(show_bet = false, only_first_card = false,
                show_value = false)

    result = ''

    # display the bet
    result += "ставка: $#{bet} | " if show_bet

    # display a busted keyword
    result += 'проиграл! | ' if is_busted?

    # display the list of cards
    cards.each_index do |c|
      card = cards[c]
      result += ', ' if c
      result += if only_first_card && c >= 1
                  '<скрытая карта>'
                else
                  card.to_string
                end
    end

    # display value only if not busted and show_value is on
    result += " | value: #{value?}" if show_value && !is_busted?
    result
  end
end
