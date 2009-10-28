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
#   V add item on POST /
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
    attr_accessor :body
    
    if !defined? OPENED
      OPENED = 'opened'
      CLOSED = 'closed'
    end
  
    def initialize
      @headers = {}
      @body = ""
    end
    
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
    
    def to_raw_file
      %{Title: #{title}\n} <<
      %{Person: #{person}\n} <<
      %{Status: #{status}\n} <<
      %{Created: #{created_at}\n} <<
      %{Modified: #{modified_at}\n} <<
      %{\n#{body}\n}
    end
    
    def id
      @id ||= Time.now.strftime("%Y%m%d-%H%M%S-#{rand(2**16)}")
    end
    
    def title
      @headers["Title"] || "Untitled"
    end
    
    def person
      @headers["Person"] || "nobody"
    end
    
    def status
      @headers["Status"] || OPENED
    end
    
    def closed?
      status == CLOSED
    end
    
    def opened?
      !closed?
    end
    
    def created_at
      @headers["Created"] && Time.parse(@headers["Created"]) || Time.now
    end
    
    def modified_at
      @modified_at ||= (@headers["Modified"] && Time.parse(@headers["Modified"]) || Time.now)
    end
    
    # mutation methods
    
    def title=(t)
      @headers['Title'] = t
    end
    
    def person=(v)
      @headers['Person'] = v
    end
    
    def status=(s) 
      if s == CLOSED || s == OPENED
        @headers['Status'] = s
      else
        raise ArgumentError, "Task status could be either Task::OPENED or Task::CLOSED"
      end
    end
    
    def close
      @headers['Status'] = CLOSED
    end
    
    def open
      @headers['Status'] = OPENED
    end
    
    def mark_as_modified
      @modified_at = Time.now
    end
    
  end
  
  
  #
  # GET
  #
  
  class Index
    include FileHelper
    include HTMLBuilder
    
    attr_accessor :page_title, :opened_tasks, :closed_tasks
    def initialize
      super
      init_html_builder
      @page_title = project_title
      @opened_tasks = []
      @closed_tasks = []
      tasks.each do |t|
        (t.closed? ? @closed_tasks : @opened_tasks) << t
      end
    end
    
    def tasks_table(tasks, opts = {}, &blk)
      opts = opts.dup
      cls = ["tasks", opts.delete(:class), opts.delete("class")].compact.join(" ")
      table({:border => 0, :class => cls}.merge(opts)) do
        tasks.each do |task|
          tr do
            td(:class => "task-title") do
              a(:href => "/#{task.id}"){ h(task.title) }
            end
            td(:class => "task-person") do
              h(task.person)
            end
          end
        end # tasks.each
        
        yield if block_given?
        
      end # table
    end
    
    def read
      html do
        head do
          meta "http-equiv" => "Content-Type", :content => "text/html; charset=UTF-8"
          link :rel => "stylesheet", :href=>"/style.css", :type => "text/css"
          title { page_title }
        end
        body :onload => "document.getElementById('newitemtitle').focus()" do
          form :action => "/title", :method => "POST" do
            h1 { input(:value => page_title, :name => :title) }
          end

          form(:action => "/", :method => "POST", :class => 'new-task') do
            tasks_table(opened_tasks, :class => "opened-tasks") do
              tfoot do
                tr do
                  td :class => "task-title" do
                    input(:name => "title", :value => "", :id => :newitemtitle)
                  end
                  td :class => "task-person" do
                    label = 'person'
                    onfocus = "if (this.value === #{label.inspect}) {this.value = ''; this.className = ''}"
                    input(:name => "person", :value => label, :id => :newitemperson, :onfocus => onfocus, :class => "empty")
                    text("&nbsp;")
                    input(:type => :submit, :value => "add")
                  end # td
                end # tr
              end # tfoot
            end # tasks_table
          end # new task form
          
          h2 { "Closed tasks" }
          
          tasks_table(closed_tasks, :class => "closed-tasks")
          
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
  # CSS
  #
  
  class CSS
    include CSSBuilder
    def initialize
      init_css_builder
    end
    def run
      font_family = "Helvetica, sans-serif"
      font = "100% #{font_family}"
      apply(:body, 
        :font => font, 
        :color => "#333",
        :margin => "3em 1em 1em 5em")
      apply(:h1, :font_size => 1.3.em) do
        with(:input,
          :font => font,
          :border => :none,
          :width => "100%",
          :outline_style => :none
        )
      end
      
      apply(:h2, :font_size => 1.1.em, :font_weight => :normal, :margin => "1.8em 0 0.5em 0") 
      
      apply(".new-task input", :font_family => font_family, :font_size => 1.0.em, :margin_left => -3.px, :padding_left => 0.px)
      apply(".empty", :color => "#999")
      apply(".tasks", :width=>"100%", :margin_left => "-1px") do
        apply("td", :font_family => font_family, :font_size => 0.9.em, :padding => "0.1em 0 0.1em 0")
        apply("td.task-person", :font_size => 0.83.em)
        apply("tfoot td", :padding_top=>"0.5em")
        
        apply("a", :color => "#333", :text_decoration => "none")
        apply("a:hover", :color => "#000", :text_decoration => "underline")
        
        apply(".task-title", :width=>"70%", :padding_right => "5px") do
          apply("input", :width=>"100%")
        end
      end
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
  
  class TaskCreate
    include FileHelper
    def initialize(query)
      @query = query
    end
    def perform
      title = @query["title"].first.to_s
      person = @query["person"].first.to_s
      task = Task.new
      task.title = title
      task.person = person
      save_task(task)
      "/"
    end
  end
  
  #
  # Helpers
  #
  
  module FileHelper
    
    def h(html)
      CGI::escapeHTML(html)
    end
    
    def file_contents_for_path(path)
      content = nil
      content = File.open(path){|f|f.read}.to_s.strip if File.readable?(path)
      return nil if content == ""
      content      
    end
    
    def file_contents_for_name(name)
      file_contents_for_path("_ampoule/#{name}")
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

    def tasks
      (Dir.glob("_ampoule/*.amp") || []).map do |path|
        t = Task.new
        if path =~ %r{/([^/]+)\.amp$}
          t.initialize_with_raw_file($1, file_contents_for_path(path))
        else
          raise "Task id is corrupted? Path: #{path}"
        end
        t
      end
    end

    def task_by_id(id)
      raw_contents = file_contents_for_name(id)
      return nil if !raw_contents
      t = Task.new
      t.initialize_with_raw_file(raw_contents)
      t
    end
        
    def save_task(task)
      raw_contents = task.to_raw_file
      set_file_contents_for_name(raw_contents, %{#{task.id}.amp})
    end
  end
  
  #
  # Content Builders
  #
  
  module HTMLBuilder
    def init_html_builder
      @_html_stack = []
    end
    def text(text)
      buf = (@_html_stack.last || "") << text
      buf if @_html_stack.empty?
    end
    def tag(name, attrs = {}, &blk)
      buf = @_html_stack.last || ""
      buf << %{<#{name}}
      if attrs
        rendered_attrs = attrs.inject('') do |ra, (k,v)|
          ra << " " << k.to_s << "=" << '"' << CGI::escapeHTML(v.to_s) << '"'
        end
        buf << rendered_attrs
      end
      if blk
        @_html_stack.push("")
        r = yield
        r = "" if !r.is_a?(String)
        buf << ">" << @_html_stack.pop << r << "</#{name}>\n"
      else
        buf << " />\n"
      end
      buf if @_html_stack.empty?
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
      elsif request.path == "/"
        location = TaskCreate.new(CGI::parse(request.body)).perform
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


