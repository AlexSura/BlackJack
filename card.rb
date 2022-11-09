# frozen_string_literal: true

class Card
  RANKS = %w[2 3 4 5 6 7 8 9 10 Jack Queen King Ace].freeze
  SUITS = %w[Clubs Diamonds Hearts Spades].freeze # масти

  attr_reader :rank, :suit, :value

  # инициализировать карту на основе идентификатора, числа от 1 до 52
  def initialize(id)
    rank_index = id % 13
    rank = RANKS[rank_index]
    suit = SUITS[id % 4]

    # Теперь определите значение.
    value =
      case rank_index
      when 0..8 then rank_index + 2
      when 9..11 then 10	# J, Q, K
      else 11 			# Ace
      end
  end

  def to_string
    "#{rank} of #{suit}"
  end
end
