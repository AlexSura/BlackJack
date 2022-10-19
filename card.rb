class Card
	RANKS = %w(2 3 4 5 6 7 8 9 10 Jack Queen King Ace)
	SUITS = %w(Clubs Diamonds Hearts Spades) #масти

	attr_accessor :rank, :suit, :value

	# инициализировать карту на основе идентификатора, числа от 1 до 52
	def initialize(id)
		rank_index = id % 13
		self.rank = RANKS[rank_index]
		self.suit = SUITS[id % 4]

		# Теперь определите значение.
		self.value = 
			case rank_index
			when  0..8 then rank_index + 2
			when 9..11 then 10 	# J, Q, K
			else 11 			# Ace 
			end
	end

	def to_string
		self.rank + " of " + self.suit
	end
end
