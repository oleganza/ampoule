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
        name, value = line.strip.split(/:\s*/,2)
        h[name] = value
        h
      end
      @body ||= ""
    end
    
    def to_raw_file
      %{Title: #{title}\n} <<
      %{Person: #{person}\n} <<
      %{Status: #{status}\n} <<
      %{Created: #{created_at}\n} <<
      %{Modified: #{modified_at}\n} <<
      %{\n#{body}}
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
    
    def comments
      Comment.comments_from_raw_file(body)
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
    
    def add_comment(current_person, comment)
      body << Comment.new(current_person, comment).to_raw_file
    end
    
    def mark_as_modified
      @modified_at = Time.now
    end
    
  end
  
  class Comment
    attr_accessor :person, :body, :date
    def initialize(person, body, date = Time.now)
      @person = person
      @body = body
      @date = date
    end
    
    def to_raw_file
      %{\n\n@comment\n} <<
      %{@author #{@person.gsub(/[\r\n]/,'')}\n} <<
      %{@date #{@date}\n} <<
      %{\n#{@body}}
    end
    
    def self.comments_from_raw_file(body)
      chunks = body.split("\n@comment\n")[1..-1] || []
      chunks.map do |chunk|
        if chunk.strip =~ /@author ([^\n]+)\n@date ([^\n]+)\n(.*)/m
          self.new($1, $3, Time.parse($2))
        else
          puts "Ampoule::Comment: could not parse chunk:\n#{chunk}\n(end of chunk)"
          nil
        end
      end
    end
    
  end
  
  
  #
  # GET
  #
  
  class Layout
    include FileHelper
    include HTMLBuilder
    attr_accessor :page_title
    def initialize
      super
      init_html_builder
      @page_title = project_title
    end
    
    def read(attrs_for_body = {})
      html do
        head do
          meta "http-equiv" => "Content-Type", :content => "text/html; charset=UTF-8"
          link :rel => "stylesheet", :href=>"/style.css", :type => "text/css"
          title { page_title }
        end
        body(attrs_for_body) do
          yield if block_given?
        end
      end # html
    end # read
  end # Layout
  
  class Index < Layout
    attr_accessor :opened_tasks, :closed_tasks
    def initialize(query)
      super()
      @opened_tasks = []
      @closed_tasks = []
      tasks.each do |t|
        (t.closed? ? @closed_tasks : @opened_tasks) << t
      end
      @closed_tasks.reverse!
    end
    
    def tasks_table(tasks, opts = {}, &blk)
      opts = opts.dup
      cls = ["tasks", opts.delete(:class), opts.delete("class")].compact.join(" ")
      table({:border => 0, :class => cls}.merge(opts)) do
        tasks.each do |task|
          tr do
            td(:class => "task-title textual") do
              a(:href => "/#{task.id}"){ h(task.title) }
              small { task.modified_at.to_relative_string_if_recent }
            end
            td(:class => "task-person textual") do
              h(task.person)
            end
          end
        end # tasks.each
        
        yield if block_given?
        
      end # table
    end
    
    def read
      super :onload => "document.getElementById('newitemtitle').focus()" do
        form :action => "/title", :method => "POST" do
          h1(:class => 'index-title') { input(:value => page_title, :name => :title) }
        end
        
        form(:action => "/", :method => "POST", :class => 'new-task') do
          tasks_table(opened_tasks, :class => "opened-tasks") do
            tfoot do
              tr do
                td :class => "task-title" do
                  input(:name => "title", :value => "", :id => :newitemtitle)
                end
                td :class => "task-person" do
                  label = 'nobody'
                  onfocus = "if (this.value === #{label.inspect}) {this.value = ''; this.className = ''}"
                  input(:name => "person", :value => ($last_assigned_person || label), :id => :newitemperson, :onfocus => onfocus, :class => ($last_assigned_person && $last_assigned_person != label ? "" : "empty"))
                  text("&nbsp;")
                  input(:type => :submit, :value => "Add")
                end # td
              end # tr
            end # tfoot
          end # tasks_table
        end # new task form
        
        h2 { "Closed tasks" }
        
        tasks_table(closed_tasks, :class => "closed-tasks")
        
      end # layout
    end # read
  end
  
  class Page < Layout
    attr_accessor :task
    def initialize(id)
      super()
      @task = task_by_id(id)
      self.page_title = @task.title + " (#{project_title})"
    end
    
    def read
      super :onload => "document.getElementById('comment').focus()" do
        
        small(:style => %{position:absolute; top:1em;}) { a(:href => "/") { project_title + " index" } }
        
        form(:action => "/#{task.id}", :method => "POST", :class => 'edit-task') do
          h1 { input(:name => "title", :value => task.title, :class => "task-title") }
          
          div :class => "comments" do
            task.comments.each do |comment|
              label :class => "comment-label" do
                text(h(comment.person))
                small { comment.date.to_relative_string }
              end
              text(formatted_text(comment.body))
            end
          end
          br
          input :class => "current-person", :name => "current_person", :value => current_user_name, :tabindex=>"-1"
          br
          textarea(:name => "comment", :id => "comment", :rows => 10, :cols => 80) { }
          div :class => "panel" do
            div :class => "assign-to" do
              text("assigned to ")
              input(:name => "person", :value => task.person)
            end
          end
          
          div :class => "buttons panel" do
            div :class => "save-button" do
              input :type => :submit, :name => :save, :value => "Save"
            end
            div :class => "status-buttons" do
              input :type => :submit, :name => :close, :value => "Close", :disabled => (task.closed? ? :disabled : nil)
              text("&nbsp;")
              input :type => :submit, :name => :reopen, :value => "Reopen", :disabled => (task.opened? ? :disabled : nil)
            end
          end
        end # form
        
      end # super do
    end # read
    
    def formatted_text(text)
      text = text.gsub(/\r\n/, "\n").gsub(/\r/, "\n")
      paragraphs = text.split(/\n\n+/)
      paragraphs.map do |paragraph|
        if paragraph[/\n[ \t]+/]
          %{<code><pre>#{h(paragraph)}</pre></code>}
        else
          %{<p>#{hbr(paragraph)}</p>}
        end
      end.join
    end
    
    def hbr(text)
      h(text.strip).gsub(/\n/, "<br/>")
    end
    
  end # Page
  
  class ::Time
    def to_relative_string
      diff = (Time.now - self).to_i
      return "now" if diff < 2
      return "#{diff} seconds ago" if diff < 50
      return "one minute ago" if diff < 60*2
      return "#{diff/60} minutes ago" if diff/60/60 <= 1
      return "#{diff/60/60} hours ago" if diff < 60*60*18
      return "yesterday" if diff/60/60/24 <= 1
      return "#{diff/60/60/24} days ago" if diff < 60*60*24*7
      return strftime("%B %d") if diff < 60*60*24*30*3
      return strftime("%B %d, %Y")
    end
    
    def to_relative_string_if_recent
      if Time.now - self < 3600
        to_relative_string
      else
        ""
      end
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
        apply(:input,
          :font => font,
          :width => "70%"
        )
      end
      
      with("h1.index-title") do
        apply(:input,
          :border => :none,
          :width => "100%",
          :outline_style => :none
        )
      end
      
      apply(:h2, :font_size => 1.1.em, :font_weight => :normal, :margin => "1.8em 0 0.5em 0", :color => "#666") 
      
      apply("a", :color => "#333")
      apply("a:hover", :color => "#000")

      
      apply(".new-task input", :font_family => font_family, :font_size => 1.0.em, :margin_left => -3.px, :padding_left => 0.px)
      apply(".empty", :color => "#999")
      apply(".tasks", :width=>"100%", :margin_left => "-1px") do
        apply("td", :font_family => font_family, :font_size => 0.9.em, :padding => "0.1em 0 0.2em 0")
        apply("td.textual", :overflow => "hidden")
        apply("td.task-person", :font_size => 0.83.em)
        apply("tfoot td", :padding_top=>"0.5em")
        
        apply("a", :color => "#333", :text_decoration => "none")
        apply("a:hover", :color => "#000", :text_decoration => "underline")
        
        apply(".task-title", :width=>"70%", :padding_right => "5px") do
          apply("input", :width=>"100%")
        end
        
        apply("small", :color => "#999", :font_size => "0.75em", :padding_left => "0.4em") 
        
      end
      
      apply(".tasks.closed-tasks") do
        apply("td", :color => "#666")
        apply("a", :color => "#666")
        apply("a:hover", :color => "#333")
      end
      
      with(".edit-task") do      
        apply("textarea",
          :padding => 0.4.em,
          :margin => "0.4em 0 0.6em 0",
          :font_size => 0.9.em,
          :font_family => font_family,
          :word_spacing => :normal,
          :width => "70%"
        )
        
        apply("input.current-person", 
          :border => :none,
          :padding => 0,
          :margin => 0,
          :outline_style => :none,
          :font_family => font_family,
          :font_size => 0.8.em,
          :font_weight => "bold")
        
        apply("div.panel", :position => :relative, :width => "70%", :overflow => :hidden, :margin_bottom => "0.5em") 
      
        with(".assign-to", :float => :right, :font_size => "0.9em") do
          apply("input", :font_size => "1em", :font_family => font_family)
        end
      
        apply(%{input[type="submit"]}, :font => font, :width => "5em")
        
        
        apply("div.status-buttons", :float => "left") 
        apply("div.save-button", :float => "right") 
      end
      
      with(".comments") do
        apply("label", :font_size => 0.8.em, :font_weight => "bold", :display => "block", :margin => "2em 0 0.6em 0") do
          apply("small", :font_size => 1.em, :color => "#999", :padding_left => 0.9.em, :font_weight => "normal")
        end
        apply("p", :font_size => 0.9.em, :margin => "0.3em 0 0.6em 0", :width => "70%", :line_height => "130%")
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
      $last_assigned_person = person
      "/"
    end
  end
  
  class TaskUpdate
    include FileHelper
    def initialize(id, query)
      @task = task_by_id(id)
      @query = query
    end
    def perform
      title = @query["title"].first.to_s
      person = @query["person"].first.to_s

      @task.title = title
      @task.person = person
      
      comment = @query["comment"].first.to_s.strip
      if comment.length > 0
        current_person = @query["current_person"].first.to_s

        if current_person != current_user_name && current_person.size > 0
          self.current_user_name = current_person # remember new value
        end
        
        @task.add_comment(current_person, comment)
      end
      
      @task.close if !@query["close"].empty?
      @task.open  if !@query["reopen"].empty?
      
      save_task(@task)
      if @query["close"].empty? && @query["reopen"].empty?
        "/#{@task.id}"
      else
        "/" # redirect to index if status was changed
      end
    end
  end
  
  #
  # Helpers
  #
  
  module GitHelper
    def git_user_name
      @git_user_name ||= `git config user.name`.strip
    end
    
    def git_user_email
      @git_user_email ||= `git config user.email`.strip
    end
    
    def git_user_name=(n)
      n = n.gsub(/["`'\\\n\r\t\v]+/, '')
      `git config user.name "#{n}"`
    end
  end
  
  module FileHelper
    include GitHelper
    
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
      raw_contents = file_contents_for_name(%{#{id}.amp})
      return nil if !raw_contents
      t = Task.new
      t.initialize_with_raw_file(id, raw_contents)
      t
    end
        
    def save_task(task)
      task.mark_as_modified
      raw_contents = task.to_raw_file
      set_file_contents_for_name(raw_contents, %{#{task.id}.amp})
    end
    
    def current_user_name=(n)
      self.git_user_name = n
    end
    
    def current_user_name
      n = git_user_name
      n = git_user_email if n.to_s == ''
      n = "Anonymous"    if n.to_s == ''
      n
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
          v ? (ra << " " << k.to_s << "=" << '"' << CGI::escapeHTML(v.to_s) << '"') : ra
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
      @port = @opts[:port].to_i
      begin
        @server = WEBrick::HTTPServer.new(:Port => @port)
      rescue Errno::EADDRINUSE
        @port += 1
        puts "Ampoule::Server: trying to bind to port #{@port}..."
        retry
      end
      @server.mount "/", WebrickHandle
    end
    def start
      Thread.new { sleep(1); system(%{open http://localhost:#{@port}/}) }
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
        body = Index.new(request.query).read
      elsif request.path == "/style.css"
        body = CSS.new.read
        content_type = "text/css"
      elsif request.path == "/favicon.ico"
        body = ""
        content_type = "application/octet-stream"
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
        location = TaskUpdate.new(request.path.to_s[1..-1], CGI::parse(request.body)).perform
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

  _ampoule_tasks/20091027-181545-463129.amp


