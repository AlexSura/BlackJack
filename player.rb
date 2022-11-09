# frozen_string_literal: true

require_relative 'deck'
require_relative 'prompt'
require_relative 'hand'

class Player
  ################### player move options ######################
  HIT = %w[h hit].freeze
  STAND = %w[st stand].freeze
  DOUBLE_DOWN = ['dd', 'double down'].freeze
  SPLIT = %w[sp split].freeze

  # ваши параметры по умолчанию
  OPTIONS = HIT | STAND

  # некоторые строковые константы
  SEP = "\n| "
  ASK_DEFAULT = "Какое действие выполнить?#{SEP}stand: enter 'st' or 'stand'#{SEP}hit: enter 'h' or 'hit'"
  ASK_DOUBLE_DOWN = "для удвоения ставки введите 'dd' или 'double down'"
  ASK_SPLIT = "split: введите 'sp' or 'split'"
  WRONG_INPUT = 'Я не могу распознать ваш ввод. Попробуйте еще раз: '

  ################ accessors + initializer ###################

  attr_accessor :id, :cash, :hands # player идентификатор   # сколько у тебя наличных?  # массив рук. У тебя обычно одна рука
  # => но вы можете иметь второй, если вы разделитесь
  attr_accessor :current_hand_index # для печати

  # инициализируем игрока номером и суммой денег
  def initialize(id, cash)
    self.id = id
    self.cash = cash
    reset_cards
  end

  ##################### вопросы ######################

  # составить имя игрока.
  def name?
    "Player #{id}"
  end

  # у игрока закончились деньги?
  def out?
    cash <= 0
  end

  # игрок дилер?
  def is_dealer?
    id == DEALER_ID
  end

  ##################### ход игрока ######################
  # повернуть счетчик за руку
  def take_turn(game)
    clear_console

    hands.each do |hand|
      # повернуть счетчик за руку
      turn = 0
      self.current_hand_index += 1
      until hand.finished_playing
        # print the state
        clear_console
        print "Player #{id}'s turn.\n"
        game.print_state_of_game
        # (bet = true, dealer_only_first_card = true, show_val = false)

        if hand.is_blackjack?
          puts 'Blackjack!'
          hand.end_play!
          wait_for_newline
        else
          # запросить ввод
          process_options game, hand, first_turn = turn.zero?
        end

        turn += 1 # увеличить счетчик оборотов
      end
    end

    self.current_hand_index += 1
  end

  # спрашивает игрока, что он/она хотел бы сделать с рукой
  def process_options(game, hand, _first_turn = false)
    valid_options = OPTIONS
    ask_string = ASK_DEFAULT

    # если у игрока две карты, мы должны добавить удвоение ставки
    # и, возможно, разделить, если применимо к valid_options
    if (hand.cards.length == 2) && (hand.bet <= cash)
      valid_options |= DOUBLE_DOWN
      ask_string += SEP + ASK_DOUBLE_DOWN

      # Проверьте, являются ли две карты одинаковыми
      if hand.can_split?
        valid_options |= SPLIT
        ask_string += SEP + ASK_SPLIT
      end
    end

    ask_string += "\n Введите свой вариант: "

    # ask for input
    option = prompt ask_string

    # продолжайте спрашивать, пока мы не получим действительный ввод
    option = prompt WRONG_INPUT until valid_options.include? option

    # анализировать параметры на основе того, находятся ли они в наборе
    case option
    when *HIT
      hit(game, hand)
    when *STAND
      stand(game, hand)
    when *SPLIT
      split(game, hand)
    else # double down
      double_down(game, hand)
    end
  end

  ################# Player choices on a hand ################

  def hit(game, hand)
    draw game.deck, hand, silent = false
    check_busted hand
  end

  def stand(_game, hand)
    puts 'Вы решили встать.'
    hand.end_play!
    wait_for_newline
  end

  def double_down(game, hand)
    puts 'Вы выбрали двойную ставку!'

    if cash >= hand.bet
      self.cash -= hand.bet
      hand.double_bet!

      # now, draw again
      draw game.deck, hand, silent = false
      check_busted hand
      hand.end_play!
    else
      puts 'недостаточно средств'
    end
  end

  def split(_game, hand)
    puts 'Ты выбрал сплит!'
    if self.cash >= hand.bet
      hands << hand.split!
      self.cash -= hand.bet
    else
      puts 'недостаточно средств'
    end
  end

  ##################### bet handling ######################

  # Zапрашиваем у игрока начальную ставку на руку[0]
  def make_initial_bet
    clear_console
    puts("Player #{id} у вас сейчас есть $#{self.cash}")

    # сделать ставку
    bet =
      prompt("Player #{id} сделать ставку!\n Введите число: $").to_i
    while (bet <= 0) || (bet > self.cash)
      bet = prompt(
        "Вы можете делать ставки от $1 до $#{self.cash}: "
      ).to_i
    end

    # настроить ставку
    hands[0].bet = bet
    self.cash -= bet
  end

  # you can win your bet on a hand
  def win_bet(hand)
    # если у вас блэкджек, выиграйте 3:2 и верните первоначальную ставку
    self.cash += if hand.is_blackjack?
                   hand.bet + (1.5 * hand.bet).round
                 else
                   2 * hand.bet
                 end
  end

  # вернуть вашу ставку, если у вас ничья с дилером
  def return_bet(hand)
    self.cash += hand.bet
  end

  # проиграть ставку (ставка переходит к дилеру)
  def lose_bet(hand)
    # hand.bet = 0
  end

  ################# Misc. Utility functions ################
  def reset_cards
    self.hands = [Hand.new]
    self.current_hand_index = -1
  end

  # взять карту из колоды в руку
  # =>  по умолчанию рука — это первая рука
  def draw(deck, hand = hands[0], silent = true)
    card = deck.draw
    hand.cards << card
    unless silent
      print "#{card.to_string} drawn. "
      wait_for_newline
    end
  end

  # проверить, не сломана ли рука
  def check_busted(hand)
    if hand.is_busted?
      puts 'проиграл!'
      lose_bet(hand)
      hand.end_play!
      wait_for_newline
    end
  end

  # строковое представление игрока
  def to_string(show_bet = true, only_first_card = false, value = false)
    sep = ' | '

    # print name and cash
    result = "| #{name?}#{sep}"
    result += "$#{self.cash}\n"

    # print each hand
    hands.each_index do |h|
      hand = hands[h]
      result += " \\ #{hand.to_string(show_bet, only_first_card, value)}"
      result += ' <- current' if h == self.current_hand_index
      result += "\n"
    end
    result
  end
end
