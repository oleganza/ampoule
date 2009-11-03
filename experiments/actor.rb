require 'thread'

class Actor
  attr_accessor :queue

  def self.new_instance(*args)
    actor = self.allocate
    actor.send(:initialize, *args)
    actor
  end
  
  def self.new(*args)
    Receiver.new(new_instance(*args))
  end
  
  def initialize
    @queue = Queue.new
    @thread = Thread.new do
      loop do
        msg, args, blk = @queue.pop
        send(msg, *args, &blk)
      end
    end
  end
  
  def stop
    @thread.join
  end
  
  def kill
    @thread.kill
  end
  
  class PeriodicTimer < Actor
    def self.new(*args)
      new_instance(*args)
    end
    def initialize(interval, receiver)
      @thread = Thread.new do
        loop do
          sleep interval
          receiver.send(:on_timer_tick, self)
        end
      end
    end
  end
  
  class Receiver
    def initialize(actor)
      @actor = actor
    end
    def send(name, *args, &blk)
      @actor.queue.push([name, args, blk])
      self
    end
    def method_missing(name, *args, &blk)
      send(name, *args, &blk)
    end
    def stop
      send(:kill)
      @actor.stop
    end
  end
  
end

if $0 == __FILE__
  
  class Pinger < Actor
    def ping!
      puts "ping!"
      sleep 1
      puts "end of ping"
    end
    def on_timer_tick(t)
      puts "."
    end
  end
  
  pinger = Pinger.new
  
  timer = Actor::PeriodicTimer.new(0.5, pinger)
  
  pinger.ping!
  pinger.ping!
  pinger.ping!
  
  sleep 2
  
  pinger.stop
end
