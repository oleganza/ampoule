require 'cgi'
require 'strscan'
module HTMLEscaper
  def self.escape(str)
    scanner = StringScanner.new(str)
    buffer = ""
    entities = {
      "<" => "&lt;",
      ">" => "&gt;",
      '"' => "&quot;",
      '&' => "&amp;"
    }
    atmark = "@"
    proto = "://"
    mailto = "mailto:"    
    while 1
      return buffer if scanner.eos?
      if s = scanner.scan_until(%r{[<>"&]|[\w\+\-_]+://|\w[\.\w]*@}um)
        m = scanner.matched
        l = m.size
        r = 0..(-1 - l)
        buffer << s[r]
        if l == 1 # entity
          buffer << entities[m]
        else # url
          url = m.dup
          if s = scanner.scan(%r{[\w&\.,%;:_/\-\?\[\]=@]+[\w/]}um)
            url << s
          end
          buffer << (block_given? && yield(url) || begin
            url = CGI::escapeHTML(url)
            pfx = nil
            if url[atmark] && !url[proto]
              pfx = mailto
            end
            %{<a href="#{pfx}#{url}">#{url}</a>}
          end)
        end
      else
        buffer << scanner.rest
        return buffer
      end
    end
  end
end

  
if $0 == __FILE__
  
  escaped = HTMLEscaper.escape( %{
    
    a & "b" <> c
    
    vasya@mail.ru, tell me one thing!
    ssh://vasya@mail.ru
    
    Look here git+ssh://oleganza@example.com:blah/blah.git:
    
    <git+ssh://oleganza@example.com:blah/blah.git>:
    
    <a class="class" href="http://example.com/?a=b&c=d">"hello"</a>
    <http://example.com/?>
    <http://example.com/?abc>
    (http://example.com)(blah)
    <http://example.com/?blah&ampersand=1>
    <http://example.com/?blah&>
  }) do |url|
    puts "Ping url #{url}"
    url = CGI::escapeHTML(url)
    %{[A HREF="#{url}"]#{url}[/A]}
    nil
  end
  
  puts escaped
  
  # Output as of November 2, 2009 (14:58)
  #
  # a &amp; &quot;b&quot; &lt;&gt; c
  # 
  # <a href="mailto:vasya@mail.ru">vasya@mail.ru</a>, tell me one thing!
  # <a href="ssh://vasya@mail.ru">ssh://vasya@mail.ru</a>
  # 
  # Look here <a href="git+ssh://oleganza@example.com:blah/blah.git">git+ssh://oleganza@example.com:blah/blah.git</a>:
  # 
  # &lt;<a href="git+ssh://oleganza@example.com:blah/blah.git">git+ssh://oleganza@example.com:blah/blah.git</a>&gt;:
  # 
  # &lt;a class=&quot;class&quot; href=&quot;<a href="http://example.com/?a=b&amp;c=d">http://example.com/?a=b&amp;c=d</a>&quot;&gt;&quot;hello&quot;&lt;/a&gt;
  # &lt;<a href="http://example.com/">http://example.com/</a>?&gt;
  # &lt;<a href="http://example.com/?abc">http://example.com/?abc</a>&gt;
  # (<a href="http://example.com">http://example.com</a>)(blah)
  # &lt;<a href="http://example.com/?blah&amp;ampersand=1">http://example.com/?blah&amp;ampersand=1</a>&gt;
  # &lt;<a href="http://example.com/?blah">http://example.com/?blah</a>&amp;&gt;  
  
end