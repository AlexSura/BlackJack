# frozen_string_literal: true

# just a few functions used to prompt the users

def prompt(*args)
  print(*args)
  gets.chomp
end

# wait until there is an enter
def wait_for_newline
  print 'Нажмите enter, чтобы продолжить...'
  gets
  print "\n"
end

# keeps prompting until number >= 1 (a Natural Number) is returned
def prompt_for_natural_number(ask, reprompt)
  result = prompt(ask).to_i
  result = prompt(reprompt).to_i while result <= 0
end

def clear_console
  print "\n\n" # just in case the console doesn't clear
  system 'clear' or system 'cls'
end
