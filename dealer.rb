# frozen_string_literal: true

require_relative 'deck'
require_relative 'prompt'

DEALER_ID = 0 # player id for dealer

# the dealer is just a very special player
class Dealer < Player
  DEALER_TURN = "It is the dealer's turn.\n"

  def initialize
    reset_cards
    self.id = DEALER_ID
  end

  # construct the player's name.
  def name?
    'Dealer'
  end

  # dealer is always in the game
  def out?
    false
  end

  # dealer makes no bets
  def make_initial_bet; end
  def win_bet(hand); end
  def lose_bet(hand); end

  # dealer's turn is deterministic
  def take_turn(game)
    hands.each do |hand|
      until hand.finished_playing
        # print the state
        clear_console
        puts DEALER_TURN
        game.print_state_of_game

        # ask for the input
        if (hand.value? >= 17) && !hand.is_busted?
          hand.end_play!
        else
          # dealer will hit until he gets >= 17 points
          draw(game.deck, hand, silent = false)
          check_busted hand
        end
      end
    end
    puts 'Дилер заканчивает свой ход'
  end

  # string representation of dealer
  def to_string(_show_bet = false, only_first_card = false, value = false)
    sep = ' | '

    result = "| Dealer\n"
    hands.each do |hand|
      # dealer has no bets, so don't show the bet.
      result += " \\ #{hand.to_string(false, only_first_card, value)}"
      result += "\n"
    end
    result
  end
end
