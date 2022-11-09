# frozen_string_literal: true

require_relative 'deck'
require_relative 'player'
require_relative 'dealer'
require_relative 'prompt'

class Game
  attr_accessor :players, :dealer, :deck, :is_game_over # list of players.  the dealer is a player       # the dealer         # a Deck instance # is the game over yet?

  START_CASH = 1000

  def initialize
    self.is_game_over = false

    puts 'Добро пожаловать в игру'
    wait_for_newline

    # get_num_players возвращает колличество указанных игроков
    num_players = get_num_players

    # глобальная стартовая сумма

    # создание игроков
    self.players = []
    (1..num_players).each { |i| players << Player.new(i, START_CASH) }

    # create the dealer, add him/her to players
    self.dealer = Dealer.new
    players << dealer

    # игра не закончится, пока все игроки не оставят свои деньги
    play_round until is_game_over

    puts 'Game over! Благодарим за игру!'
  end

  # prompt for the number of human players
  def get_num_players
    num_players =
      prompt("Сколько человек играет?\nВведите число: ").to_i
    num_players = prompt('Введите число больше 0:').to_i while num_players <= 0
    num_players
  end

  # prompt for how much each person should start with. Not actually called.
  def get_start_cash
    start_cash =
      prompt(
        "С какой суммы будет начинаться первоночальная ставка?\nВведите число: $"
      ).to_i
    start_cash = prompt('Введите число больше, чем 0: ').to_i while start_cash <= 0
    start_cash
  end

  ######################### функционал игры #######################

  # сыграть раунд игры. это постоянно зацикливается
  def play_round
    self.deck = Deck.new

    # reset players' cards, have them make bets, and then deal
    reset_cards
    make_bets
    deal_cards

    # if the dealer has blackjack, play immediately ends
    if dealer.hands[0].is_blackjack?
      clear_console
      puts 'Dealer has blackjack!'
      print_state_of_game
      wait_for_newline
    else
      # let every player take their turns
      players.each do |player|
        clear_console
        player.take_turn(self)
      end
    end

    # now, calculate how much people win/lose
    resolve_bets
    wait_for_newline

    # finish with a summary of the round and remove players with 0 cash
    print_round_summary
    remove_players
  end

  # return all cards to dealer.  deck is automatically shuffled
  def reset_cards
    self.deck = Deck.new
    players.each(&:reset_cards)
  end

  # have everyone make their bets
  def make_bets
    players.each(&:make_initial_bet)
  end

  # deal one card to everyone twice
  def deal_cards
    (0..1).each do |_i|
      players.each { |player| player.draw(deck) }
    end
  end

  # remove the players who have no cash left
  def remove_players
    to_remove = []
    players.each do |player|
      to_remove << player if player.out?
    end
    to_remove.each { |player| players.delete(player) }
    self.is_game_over = true if players.length == 1
  end

  # call this after play ends to resolve bets
  def resolve_bets
    dealer_hand = dealer.hands[0]

    # Case 1: dealer goes bust
    # => if a player's hand was bust, do nothing
    # => otherwise, the hand wins
    if dealer_hand.is_busted?
      players.each do |player|
        player.hands.each do |hand|
          player.win_bet hand unless hand.is_busted?
        end
      end

    # Case 2: dealer is not bust
    # => if a hand went bust, do nothing
    # => otherwise, if the hand's value is greater, the hand wins the bet
    # => otherwise, if the hand's value is smaller, the hand wins the bet
    # => otherwise, if the hand and dealer are tied, the money is pushed back
    else
      players.each do |player|
        player.hands.each do |hand|
          if !player.is_dealer? && !hand.is_busted?

            if hand.value? > dealer_hand.value?
              player.win_bet hand

            elsif hand.value? < dealer_hand.value?
              player.lose_bet hand

            else # dealer and player are tied
              player.return_bet hand
            end

          end
        end
      end
    end
  end

  ######################### Printing functions #######################

  def print_round_summary
    # print a summary
    clear_console
    puts '-------------------- Round Summary ----------------------'
    print_state_of_game(bet: false, only_first_card: false, show_val: true)

    # say we're going to remove players.
    # actual removal occurs in remove_players
    players.each do |player|
      puts "Removing #{player.name?} due to having $0 left." if player.out?
    end

    wait_for_newline
  end

  # things that the players see
  def print_state_of_game(bet = true, dealer_only_first_card = false,
                          show_val = false)

    puts '------------------------ Table --------------------------'
    players.each_index do |p|
      player = players[p]

      # formatting
      puts '|' if p 

      # hide the dealer's card if necessary
      only_first_card = if player.is_dealer?
                          dealer_only_first_card
                        else
                          false
                        end

      # hurray!
      puts player.to_string(bet, only_first_card, show_val)
    end
    puts '---------------------------------------------------------'
  end
end
