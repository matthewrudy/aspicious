require File.dirname(__FILE__) + '/../lib/aspicious'
class Tourist
  def initialize(name)
    @name = name
  end
  attr_reader :name
  
  def take_a_picture
    puts "*FLASH*"
  end
  
  def enjoy!
    puts "enjoyed that!"
  end
end

class BurgerKing
  def enjoy!
    puts "enjoy your burger"
  end
end

puts "before any Aspiciousness"
tommy = Tourist.new("Tommy")
tommy.take_a_picture

class Beggar < Aspicious::Watcher
  watch Tourist
  after(:take_a_picture, :ask_for_money)
  
  def ask_for_money
    puts "you take picture, #{watchee.name}, you give me $1"
  end
end

puts "\n\nwith a Beggar"
tommy.take_a_picture

puts "\n\nbefore the Spoilter"
burger = BurgerKing.new
burger.enjoy!

class Spoiler < Aspicious::Watcher
  watch Tourist, BurgerKing
  before(:enjoy!, :spoil_it!)
  after :enjoy!, :spoil_it!, :only => Tourist
  after :enjoy!, :boil_it,   :only => BurgerKing
  def spoil_it!
    puts "I always spoil everything"
  end
  
  def boil_it
    puts "I always boil everything"
  end
end

puts "\n\nafter the Spoiler"
burger.enjoy!
tommy.enjoy!