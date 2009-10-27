#!/usr/bin/env ruby
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
#   V webrick setup
#   - show items list on GET /
#   - show single item on GET /id
#   - add item on POST /
#   - edit item on POST /id
# - push/pull automatically
# - search index
# - browse per-page history
# - configure server port
# - platform-independent "open" shell command
# - instead of priorities, add a checkbox "inbox": checked => p1, unchecked => p2 (checked on creation)

require 'webrick'
require 'CGI'

module Ampoule
  module FileHelper; end
  module HTMLBuilder; end
  module CSSBuilder; end

  #
  # Model
  #
  
  class Task
    
    def initialize_with_raw_file(id, raw_file)
      @modified_at = nil
      @id = id
      headers, @body = raw_file.split("\n\n", 2)
      @headers = headers.strip.split("\n").inject({}) do |h, line|
        name, value = line.strip.split(/:\s*/)
        h[name] = value
        h
      end
    end
    
    def id
      @id ||= Time.now.strftime("%Y%m%d-%H%M%S-#{rand(2**16)}")
    end
    
    def body
      @body
    end
    
    def title
      @headers["Title"] || "Untitled"
    end
    
    def person
      @headers["Person"] || "nobody"
    end
    
    def status
      @headers["Status"] || "opened"
    end
    
    def closed?
      status == "closed"
    end
    
    def opened?
      !closed?
    end
    
    def created_at
      Time.parse(@headers["Created"]) || Time.now
    end
    
    def modified_at
      @modified_at ||= Time.parse(@headers["Modified"]) || Time.now
    end
    
    def mark_as_modified
      @modified_at = Time.now
    end
    
    def to_raw_file
      %{Title: #{title}\n} <<
      %{Person: #{person}\n} <<
      %{Status: #{status}\n} <<
      %{Created: #{created_at}\n} <<
      %{Modified: #{modified_at}\n} <<
      %{\n#{body}\n}
    end
  end
  
  
  #
  # GET
  #
  
  class Index
    include FileHelper
    include HTMLBuilder
    
    attr_accessor :page_title, :tasks
    def initialize
      super
      init_html_builder
      @page_title = project_title
      @tasks = []
    end
    
    def read
      html do
        head do
          meta "http-equiv" => "Content-Type", :content => "text/html; charset=UTF-8"
          link :rel => "stylesheet", :href=>"/style.css", :type => "text/css"
          title { page_title }
        end
        body do
          form :action => "/title", :method => "POST" do
            h1 { input(:value => page_title, :name => :title) }
          end
          
          br
          
          table(:border => 0) do
            tasks.each do |task|
              tr do
                td(:class => "task-title") do
                  a(:href => "/#{task.id}"){ h(task.title) }
                end
                td(:class => "task-person") do
                  h(task.person)
                end
                td(:class => "task-status #{task.status}") do
                  h(task.status)
                end
              end
            end
          end
          
          form(:action => "/", :method => "POST", :class => 'new-task') do
            
            input(:name => "title", :value => "New task", :class => "empty", :onclick => "alert(this.classNames)")
            
            
          end
          
        end
      end
    end
  end
  
  class Page
    include FileHelper
    include HTMLBuilder
    
    def initialize(id)
      init_html_builder
    end
    
    def read
      
    end
  end
  
  #
  # POST
  #
  
  class TitleUpdate
    include FileHelper
    def initialize(query)
      @query = query
    end
    def perform
      new_title = @query["title"].first.to_s
      set_project_title(new_title)
      "/"
    end
  end
  
  #
  # CSS
  #
  
  class CSS
    include CSSBuilder
    def initialize
      init_css_builder
    end
    def run
      app_font = "1em Helvetica, sans-serif"
      apply(:body, 
        :font => app_font, 
        :color => "#333",
        :margin => "3em 1em 1em 5em")
      apply(:h1, :font_size => 1.3.em) do
        with(:input,
          :font => app_font,
          :border => :none,
          :width => "100%",
          :outline_style => :none
        )
      end
      
      with(".new-task") do
        apply(:input, :font => app_font)
        apply("input.empty", :color => "#999")
      end
    end
  end
  
  #
  # Helpers
  #
  
  module FileHelper
    
    def h(html)
      CGI::escapeHTML(html)
    end
    
    def file_contents_for_name(name)
      path = "_ampoule/#{name}"
      content = nil
      content = File.open(path){|f|f.read}.to_s.strip if File.readable?(path)
      return nil if content == ""
      content
    end
    
    def set_file_contents_for_name(content, name)
      path = "_ampoule/#{name}"
      Dir.mkdir("_ampoule") if !File.exists?("_ampoule")
      File.open(path, 'w'){|f|f.write(content)}
    end
    
    def project_title
      (file_contents_for_name("title.txt") || "Click here to change project name").strip
    end

    def set_project_title(new_title)
      set_file_contents_for_name(new_title, "title.txt")
    end
  end
  
  #
  # Content Builders
  #
  
  module HTMLBuilder
    def init_html_builder
      @_html_stack = [""]
    end
    def tag(name, attrs = {}, &blk)
      buf = @_html_stack.last
      buf << %{<#{name}}
      if attrs
        rendered_attrs = attrs.inject('') do |ra, (k,v)|
          ra << " " << k.to_s << "=" << '"' << CGI::escapeHTML(v.to_s) << '"'
        end
        buf << rendered_attrs
      end
      if blk
        @_html_stack.push("")
        buf << ">" << yield.to_s << "</#{name}>"
        @_html_stack.pop
      else
        buf << " />"
      end
      buf
    end
    def method_missing(name, *args, &blk)
      tag(name, *args, &blk)
    end
  end
  
  module CSSBuilder
    
    class ::Numeric
      def em; "#{self}em"; end
      def px; "#{self}px"; end
    end
    
    def init_css_builder
      @css_rules = {}
      @scope_stack = [];
      run
    end
    
    def with(*args, &blk)
      apply(*args, &blk)
    end
    
    def apply(rule, props = nil, &blk)
      @scope_stack.push(rule.to_s)
      full_rule = @scope_stack.join(" ")
      @css_rules[full_rule] = (@css_rules[full_rule] || {}).merge(props) if props
      if blk
        yield
      end
      @scope_stack.pop
    end
    
    def read
      @css_rules.inject("") do |css, (k, v)|
        css << k << " {\n" << (v.inject("") { |props, (p,pv)|
          props << p.to_s.gsub("_","-") << ": #{pv};\n"
        }) << "}\n"
      end
    end
  end
  
  #
  # Server config
  #
  
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
      load(__FILE__) if ENV['AMPOULE_AUTORELOAD']
      content_type = "text/html"
      if request.path == "/"
        body = Index.new.read
      elsif request.path == "/style.css"
        body = CSS.new.read
        content_type = "text/css"
      else
        body = Page.new(request.path.to_s[1..-1]).read
      end
      response.status = 200
      response['Content-Type'] = content_type
      response.body = body
    end
    
    def do_POST(request, response)
      # TODO: do the job, get redirect url and set a header to redirect there
      content_type = "text/html"
      if request.path == "/title"
        location = TitleUpdate.new(CGI::parse(request.body)).perform
      else
        raise "TODO: post to #{request.path}"
      end
      response.status = 301
      response['Location'] = location
      response['Content-Type'] = "text/html"
    end
  end
  
end

if $0 == __FILE__
  if !defined?(Ampoule::ServerInstance)
    Ampoule::ServerInstance = Ampoule::Server.new(:port => 8000)
    Ampoule::ServerInstance.start
  end
end




__END__

1. Each item is a page which looks like HTTP request (headers + body):

Title: html ui mockup\n
Person: oleganza\n
Status: opened\n
Created: Tue Oct 27 16:35:01 2009 +0100
Modified: Tue Oct 29 22:01:56 2009 +0100
\n
Arbitrary text goes here.
With as many lines as you 
can imagine.

2. Items are stored under unique filenames:

  _ampoule_tasks/2009-10-27-18.15.45.463129.task


