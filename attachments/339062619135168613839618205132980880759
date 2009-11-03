def css
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
    apply("td", :color => "#666")
    apply("a", :color => "#666")
    apply("a:hover", :color => "#333")
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
