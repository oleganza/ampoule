# Updated: 27 October, 2009 by Oleg Andreev
#
#
#                        MIT LICENSE
#
# Copyright (c) 2009 Oleg Andreev <oleganza@gmail.com>
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.


#  TODO:
# - implement minimal ui so that i can put the rest of this list under ampoule
#   - webrick setup
#   - show items list on GET /
#   - show single item on GET /id
#   - add item on POST /
#   - edit item on POST /id
# - push/pull automatically
# - search index
# - browse per-page history
# - configure server port
# - platform-independent "open" shell command

require 'webrick'
require 'CGI'

module Ampoule
  
  class HTMLBuilder
    def initialize(*args, &blk)
      @_html_stack = [""]
    end
    def tag(name, attrs = {}, &blk)
      buf = @_html_stack.last
      buf << %{<#{name}}
      if attrs
        rendered_attrs = attrs.inject('') do |ra, (k,v)|
          ra << " " << k << "=" << '"' << CGI::escapeHTML(v) << '"'
        end
        buf << " " << rendered_attrs
      end
      if blk
        @_html_stack.push("")
        buf << ">" << yield.to_s << "</#{name}>"
        @_html_stack.pop
        buf << "</#{name}>"
      else
        buf << " />"
      end
      buf
    end
    def method_missing(name, *args, &blk)
      tag(name, *args, &blk)
    end
  end
  
  class IndexController < HTMLBuilder
    def read
      html do
        head do
          title { "Ampoule" }
        end
        body do
          h1 { "Welcome!" }
        end
      end
    end
  end
  
  class PageController < HTMLBuilder
    def read
      
    end
  end
  
  class Server
    def initialize(opts = {})
      @opts = opts
      @server = WEBrick::HTTPServer.new(:Port => @opts[:port])
      @server.mount "/", WebrickHandle
    end
    def start
      Thread.new { sleep(1); system(%{open http://localhost:#{@opts[:port]}/}) }
      trap("INT") { @server.shutdown }
      @server.start
    end
  end
  
  class WebrickHandle < WEBrick::HTTPServlet::AbstractServlet
    def initialize(server, *args)
      super(server)
    end
    def do_GET(request, response)
      if request.path == "/"
        body = IndexController.new.read
      else
        body = PageController.new(:id => request.path.to_s[1..-1]).read
      end
      response.status = 200
      response['Content-Type'] = "text/html"
      response.body = body
    end
    def do_POST(request, response)
      # TODO: do the job, get redirect url and set a header to redirect there
    end
  end
  
end


if $0 == __FILE__
  Ampoule::Server.new(:port => 8000).start
end




__END__

1. Each item is a page which looks like HTTP request (headers + body):

Title: html ui mockup\n
Assigned: oleganza@gmail.com\n
Status: opened\n
\n
Arbitrary text goes here.
With as many lines as you 
can imagine.

2. Items are stored under unique filenames:

  _ampoule_tasks/ab58ef4da89b7c56ef2.amp


