class Module
  # stolen from Rails 2.2
  def alias_method_chain(target, feature)
    with_method, without_method = name_for_alias_method(target, feature, :with), name_for_alias_method(target, feature, :without)
    
    alias_method without_method, target
    alias_method target, with_method
    
    case
    when public_method_defined?(without_method)
      public target
    when protected_method_defined?(without_method)
      protected target
    when private_method_defined?(without_method)
      private target
    end
  end
  
  def name_for_alias_method(target, feature, with)
    raise(ArgumentError, "with must be :with or :without") unless [:with, :without].include?(with)
    aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
    "#{aliased_target}_#{with}_#{feature}#{punctuation}"
  end
  
  def depunctuate(method_name)
    method_name = method_name.to_s.dup
    [['?', '_question_'], ['!', '_bang_'], ['=', '_equals_']].each do |punctuation, replacement|
      method_name.gsub!(punctuation, replacement)
    end
    return method_name
  end
end

class Aspicious
  def initialize(watchee)
    @watchee = watchee
  end
  
  class << self
    def watch(*klasses)
      @watching ||= []
      klasses.each do |klass|
        @watching << klass
        klass.class_eval <<-RUBY, __FILE__, __LINE__
          unless self.instance_methods.include?('watchers')
            attr_accessor :watchers
            def watcher_for(klass)
              self.watchers ||= []
              unless watcher = self.watchers.detect{|w| w.is_a?(klass)}
                watcher = klass.new(self)
                self.watchers << watcher
              end
              return watcher
            end
          end
        RUBY
      end
    end
  
    def before(method_to_watch, callback, options={})
      do_watch(method_to_watch, callback, options, :before)
    end
    
    def after(method_to_watch, callback, options={})
      do_watch(method_to_watch, callback, options, :after)
    end
    
    private
    
    def do_watch(watch, callback, options, position)
      method_extension = depunctuate("watcher_executing_#{callback}_#{position}")
      call_watcher = "self.watcher_for(#{self}).#{callback}"
      
      klasses = options[:only] || @watching
      Array(klasses).each do |klass|
        klass.class_eval <<-RUBY, __FILE__, __LINE__
          def #{name_for_alias_method(watch, method_extension, :with)}(*args, &block)
            #{call_watcher if position == :before}
            rtn = #{name_for_alias_method(watch, method_extension, :without)}(*args, &block)
            #{call_watcher if position == :after}
            return rtn
          end
          alias_method_chain #{watch.inspect}, #{method_extension.inspect}
        RUBY
      end
    end
    
    def method_extension(callback)
      depunctuate("watcher_executing_#{callback}")
    end
  end
end

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

class Watcher < Aspicious
  watch Tourist
  after(:take_a_picture, :ask_for_money)
  
  def ask_for_money
    puts "you take picture, you give me $1"
  end
end

class Spoiler < Aspicious
  watch Tourist, BurgerKing
  before(:enjoy!, :spoil_it)
  after :enjoy!, :boil_it, :only => Tourist
  def spoil_it
    puts "I always spoil everything"
  end
  
  def boil_it
    puts "I always boil everything"
  end
end