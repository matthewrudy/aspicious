module Aspicious
  class Watcher
    def initialize(watchee)
      @watchee = watchee
    end
    attr_reader :watchee
  
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
        with_method    = depunctuate("#{watch}_with_watcher_executing_#{callback}_#{position}")
        without_method = depunctuate("#{watch}_without_watcher_executing_#{callback}_#{position}")
        call_watcher = "self.watcher_for(#{self}).#{callback}"
        
        klasses = options[:only] || @watching
        Array(klasses).each do |klass|
          klass.class_eval <<-RUBY, __FILE__, __LINE__
            def #{with_method}(*args, &block)
              #{call_watcher if position == :before}
              rtn = #{without_method}(*args, &block)
              #{call_watcher if position == :after}
              return rtn
            end
            alias :#{without_method} :#{watch}
            alias :#{watch} :#{with_method} 
          RUBY
        end
      end
      
      def depunctuate(method_name)
        method_name = method_name.to_s.dup
        [['?', '_question_'], ['!', '_bang_'], ['=', '_equals_']].each do |punctuation, replacement|
          method_name.gsub!(punctuation, replacement)
        end
        return method_name
      end
    end
  end
end
