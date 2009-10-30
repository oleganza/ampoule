require 'cgi'

class BlankSlate
  class <<self; alias __undef_method undef_method; end
  alias __instance_eval instance_eval
  ancestors.inject([]){|m,a| m + a.methods }.uniq.
    each { |m| (__undef_method(m) rescue nil) unless m =~ /^__/ }
end

class XMLBuilder < BlankSlate
  def initialize(&blk)
    @buffer = ""
    __instance_eval(&blk)
  end
  
  def puts(s)
    print("#{s}\n")
  end
    
  def print(text)
    @buffer << text
    ""
  end
  
  def tag(name, attrs = {}, &blk)
    @buffer << %{<#{name}} << (attrs || {}).inject('') do |ra, (k,v)|
      v ? (ra << " " << k.to_s << "=" << '"' << CGI::escapeHTML(v.to_s) << '"') : ra
    end
    if blk
      @buffer << ">" << yield.to_s << "</#{name}>"
    else
      @buffer << " />"
    end
    ""
  end
  
  def method_missing(name, *args, &blk)
    tag(name, *args, &blk)
  end
  
  def helper(name, &implementation)
    class <<self; self; end.send(:define_method, name, &implementation)
  end
  
  def to_s
    @buffer
  end
end


color = "red"

s = XMLBuilder.new do 
  
  helper :block do |cls, &blk|
    div(:class => "block #{cls}") do
      blk.call
    end
  end
  
  html :xmlns => :namespace do
    body do
      text("prefix")
      block(color) do
        text "inner #{color} text!"
      end
      puts "suffix1"
      puts "suffix2"
    end
    "puffix"
  end
  
  
end.to_s

puts s


