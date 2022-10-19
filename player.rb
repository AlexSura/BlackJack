require_relative 'deck'
require_relative 'prompt'
require_relative 'hand'

class Player

  ################### player move options ######################
  HIT = %w(h hit) 
  STAND = %w(st stand)
  DOUBLE_DOWN = ["dd", "double down"]
  SPLIT = %w(sp split)

  # ваши параметры по умолчанию
  OPTIONS = HIT | STAND

  # некоторые строковые константы
  SEP = "\n| "
  ASK_DEFAULT = "Какое действие выполнить?"  + SEP+
      "stand: enter 'st' or 'stand'"  + SEP+
      "hit: enter 'h' or 'hit'" 
  ASK_DOUBLE_DOWN = "для удвоения ставки введите 'dd' или 'double down'"  
  ASK_SPLIT = "split: введите 'sp' or 'split'"
  WRONG_INPUT = "Я не могу распознать ваш ввод. Попробуйте еще раз: "

  ################ accessors + initializer ###################

  attr_accessor :id     # player идентификатор
  attr_accessor :cash   # сколько у тебя наличных?
  attr_accessor :hands  # массив рук. У тебя обычно одна рука
                        # => но вы можете иметь второй, если вы разделитесь
  attr_accessor :current_hand_index # для печати

  # инициализируем игрока номером и суммой денег
  def initialize(id, cash)
    self.id = id
    self.cash = cash
    self.reset_cards
  end

  ##################### вопросы ######################

  # составить имя игрока. 
  def name?
    "Player " + self.id.to_s
  end

  # у игрока закончились деньги?
  def out?
    self.cash <= 0
  end

  # игрок дилер?
  def is_dealer?
    self.id == DEALER_ID
  end

  ##################### ход игрока ######################
  # повернуть счетчик за руку
  def take_turn(game)
    clear_console

    self.hands.each do |hand|
      # повернуть счетчик за руку
      turn = 0
      self.current_hand_index += 1
      while not hand.finished_playing
        # print the state
        clear_console
        print "Player " + self.id.to_s + "'s turn.\n"
        game.print_state_of_game(
          bet = true, dealer_only_first_card = true, show_val = false)

        if hand.is_blackjack?
          puts "Blackjack!"
          hand.end_play!
          wait_for_newline
        else 
          # запросить ввод
          process_options game, hand, first_turn = (turn == 0)
        end

        turn += 1 #увеличить счетчик оборотов
      end
    end

    self.current_hand_index += 1
  end

  # спрашивает игрока, что он/она хотел бы сделать с рукой
  def process_options(game, hand, first_turn = false)
    valid_options = OPTIONS
    ask_string = ASK_DEFAULT

    # если у игрока две карты, мы должны добавить удвоение ставки 
    # и, возможно, разделить, если применимо к valid_options
    if hand.cards.length == 2 and hand.bet <= self.cash
      valid_options |= DOUBLE_DOWN
      ask_string += SEP + ASK_DOUBLE_DOWN

      # Проверьте, являются ли две карты одинаковыми
      if hand.can_split?
        valid_options |= SPLIT
        ask_string += SEP + ASK_SPLIT
      end
    end

    ask_string += "\nType your option: "

    # ask for input
    option = prompt ask_string

    # продолжайте спрашивать, пока мы не получим действительный ввод
    while not valid_options.include? option
        option = prompt WRONG_INPUT
    end

    # анализировать параметры на основе того, находятся ли они в наборе
    case option
    when *HIT
      self.hit(game, hand)
    when *STAND
      self.stand(game, hand)
    when *SPLIT
      self.split(game, hand)
    else # double down
      self.double_down(game, hand) 
    end
  end

  ################# Player choices on a hand ################

  def hit(game, hand)
    self.draw game.deck, hand, silent = false
    self.check_busted hand
  end

  def stand(game, hand)
    puts "Вы решили встать."
    hand.end_play!
    wait_for_newline
  end

  def double_down(game, hand)
    puts "Вы выбрали двойную ставку!"

    if self.cash >= hand.bet
      self.cash -= hand.bet
      hand.double_bet!

      # now, draw again
      self.draw game.deck, hand, silent = false
      self.check_busted hand
      hand.end_play!
    else
      puts "недостаточно средств"
    end
  end

  def split(game, hand)
    puts "Ты выбрал сплит!"
    if self.cash >= hand.bet
      self.hands << hand.split!
      self.cash -= hand.bet
    else
      puts "недостаточно средств"
    end
  end

  ##################### bet handling ######################

  # Zапрашиваем у игрока начальную ставку на руку[0]
  def make_initial_bet
    clear_console
    puts("Player " + self.id.to_s + " у вас сейчас есть $" + self.cash.to_s)

    # сделать ставку
    bet =  
      prompt("Player " + self.id.to_s + " сделать ставку!\n Введите число: $").to_i
    while bet <= 0 or bet > self.cash
      bet = prompt(
        "Вы можете делать ставки от $1 до $" + self.cash.to_s + ": ").to_i
    end

    # настроить ставку
    self.hands[0].bet = bet
    self.cash -= bet
  end

  # you can win your bet on a hand
  def win_bet(hand)
    # если у вас блэкджек, выиграйте 3:2 и верните первоначальную ставку
    if hand.is_blackjack?
      self.cash += hand.bet + (1.5*hand.bet).round
    else
      self.cash += 2*hand.bet
    end
  end

  # вернуть вашу ставку, если у вас ничья с дилером
  def return_bet(hand)
    self.cash += hand.bet
  end

  # проиграть ставку (ставка переходит к дилеру)
  def lose_bet(hand)
    #hand.bet = 0
  end 

  ################# Misc. Utility functions ################
  def reset_cards
    self.hands = [Hand.new]
    self.current_hand_index = -1
  end

  # взять карту из колоды в руку
  # =>  по умолчанию рука — это первая рука
  def draw(deck, hand = self.hands[0], silent = true)
    card = deck.draw 
    hand.cards << card 
    if !silent
      print card.to_string + " drawn. "
      wait_for_newline
    end
  end

  # проверить, не сломана ли рука
  def check_busted (hand)
    if hand.is_busted?
      puts "проиграл!"      
      self.lose_bet(hand)
      hand.end_play!
      wait_for_newline
    end
  end

  # строковое представление игрока
  def to_string(show_bet=true, only_first_card = false, value = false)
    sep = " | "

    # print name and cash
    result = "| " + self.name? + sep 
    result += "$" + self.cash.to_s + "\n"

    # print each hand
    hands.each_index do |h|
      hand = hands[h]
      result += " \\ " + hand.to_string(show_bet, only_first_card, value)
      if h == self.current_hand_index
        result += " <- current"
      end
      result += "\n"
    end
    return result
  end

end
