require 'thread'

class Actor
  attr_accessor :queue
  
  def self.new
    actor = self.allocate
    actor.send(:initialize)
    Receiver.new(actor)
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
  
  def prejoin
    @thread.join
  end
  
  def join
    @thread.kill
  end
  
  def kill
    @thread.kill
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
    def join
      send(:join)
      @actor.prejoin
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
  end
  
  pinger = Pinger.new
  
  pinger.ping!
  pinger.ping!
  pinger.ping!
  
  pinger.join
end
