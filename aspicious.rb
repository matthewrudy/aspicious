class Tourist
  def take_a_picture
    puts "*FLASH*"
  end
end

class Aspicious
  class << self
    def watch(klass)
      @watching ||= []
      @watching << klass
    end
  
    def after(watch, callback)
      @watching.each do |klass|
        klass.class_eval <<-RUBY
          def #{watch}_with_watcher_executing_#{callback}(*args, &block)
            rtn = #{watch}_without_watcher_executing_#{callback}(*args, &block)
            #{self}.new.#{callback}(self)
            return rtn
          end
          alias :#{watch}_without_watcher_executing_#{callback} :#{watch}
          alias :#{watch} :#{watch}_with_watcher_executing_#{callback}
        RUBY
      end
    end
  end
end

class Watcher < Aspicious
  watch Tourist
  after(:take_a_picture, :ask_for_money)
  
  def ask_for_money(watched)
    puts "you take picture, you give me $1"
  end
end
