class BlankSlate
  class <<self; alias __undef_method undef_method; end
  alias __instance_eval instance_eval
  ancestors.inject([]){|m,a| m + a.methods }.uniq.
    each { |m| (__undef_method(m) rescue nil) unless m =~ /^__/ }
end

class CSSBuilder < BlankSlate
  
  class ::Numeric
    def em; "#{self}em"; end
    def px; "#{self}px"; end
  end
  
  def initialize(&blk)
    @css = {}
    @current_selector = ""
    @current_rules = {}
    __instance_eval(&blk)
  end
  
  def _selector(name, suffix = "", &blk)
    # 0. prepare
    suffix = ":#{suffix}" if suffix.is_a?(Symbol)
    selector = "#{name}#{suffix}"
    
    # 1. push
    current_selector = @current_selector
    @current_selector = "#{current_selector} #{selector}".strip
    rules = @current_rules
    @current_rules = {}
    
    yield
    
    # 2. remember collected stuff
    @css[@current_selector] ||= {}
    @css[@current_selector].merge! @current_rules
    
    # 3. pop
    @current_rules = rules
    @current_selector = current_selector
  end
  
  # define an element
  def _(suffix = "", &blk)
    _selector("", suffix, &blk)
  end
  
  # set any property as-is
  def _set(name, value)
    @current_rules[name.to_s] = value
    nil
  end
  
  def _property(name, value_or_hash)
    if value_or_hash.is_a?(Hash)
      value_or_hash.inject(nil) do |r, (k, v)|
        _property("#{name}-#{k}", v)
      end
    else
      _set(name.to_s.gsub("_","-"), value_or_hash)
    end
  end
  
  def method_missing(name, *args, &blk)
    if blk # it is a selector
      _selector(name, *args, &blk)
    else # it is a property
      _property(name, *args)
    end
  end
  
  def to_s
    @css.inject("") do |css, (selector, props)|
      css << "#{selector} {\n" << (props.inject("") { |_, (k,v)|
        _ << "  #{k}: #{v};\n"
      }) << "}\n"
    end
  end
  
end


if $0 == __FILE__
  
  css = CSSBuilder.new do
    app_font_family = "Helvetica, sans-serif"

    body {
      font   "100% #{app_font_family}"
      color  "#333"
      margin "3em 1em 1em 4em"    
    }

    h1 {
      font_size 1.3.em

      input {
        font  "100% #{app_font_family}"
        width "70%"
      }
    }

    h1 ".index-title" do
      input {
        border        :none
        width         "100%"
        outline_style :none
      }
    end

    h2 { 
      font :size => 1.1.em, :weight => :normal
      margin "1.8em 0 0.5em 0"
      color "#666"
    }

    a { color "#333" }
    a(:hover) { color "#000" }

    _ ".new-task" do
      input do
        font :family => app_font_family, :size => 1.0.em
        margin_left  -3.px
        padding_left  0.px
      end
    end

    _ ".tasks" do
      width       "100%"
      margin_left "-1px"

      td do 
        font     :family => app_font_family, :size => 0.9.em
        padding  "2px 0 5px 0"

        _(".textual") { vertical_align :top }
        _(".task-person") { font_size 0.83.em }
      end

      _ ".new-task-row td" do
        padding_top "0.5em"
      end

      a         { color "#333"; text_decoration :none }
      a(:hover) { color "#000"; text_decoration :underline }

      _ ".task-title" do
        width "70%"
        padding_right "7px"

        input { width "100%" }
      end

      small {
        color "#999"
        font_size 0.75.em
        padding_left 0.4.em
      }

    end

    _ ".tasks.closed-tasks" do
      td { color "#666" }
      a  { color "#666" }
      a(:hover) { color "#333" }
    end

    _ ".edit-task" do
      textarea do
        font :size => 0.9.em, :family => app_font_family
        padding 0.4.em
        margin "0.4em 0 0.6em 0"
        word_spacing :normal
        width "70%"
      end

      input ".current-person" do
        padding 0
        margin 0
        border :none
        outline_style :none
        font :size => 0.8.em, :family => app_font_family, :weight => :bold
      end

      div ".panel" do 
        position :relative
        width "70%"
        overflow :hidden
        margin_bottom 0.5.em
      end

      _ ".save-button .assigned-to" do
        font_size 0.9.em
        input do 
          font :size => 1.0.em, :family => app_font_family
          margin_right 0.6.em 
        end
      end

      input '[type="submit"]' do
        font_family app_font_family
        width 5.em
      end

      div(".status-buttons") { float :left }
      div(".save-button")    { float :right }
    end

    _ ".comments" do
      label {
        font :size => 0.8.em, :weight => :bold
        display :block
        margin "2em 0 0.6em 0"
        small {
          font :size => 1.em, :weight => :normal
          color "#999"
          padding_left 0.9.em
        }
      }

      p {
        font_size 0.9.em
        margin "0.3em 0 0.6em 0"
        width "70%"
        line_height "130%"
      }
    end
  end
  
  puts css.to_s
  
end