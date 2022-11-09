# frozen_string_literal: true

require_relative 'card'

class Deck
  attr_reader :cards

  # initialize путем создания и перетасовки колоды
  def initialize
    cards = []
    (0..51).each { |i| cards << Card.new(i) }
    cards.shuffle!
  end

  def draw
    cards.pop
  end

  def has_cards?
    !cards.empty?
  end
end
