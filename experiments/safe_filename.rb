
filenames = %{
  
  file.txt
  Screen shot 2009-11-03 at 9.00.09 .png
  "quotes'every'where"
  /crazy\\slashes/\\
  ......dots....
  
}.strip.split("\n")

def safe_filename(n, prefix = Time.now.strftime("%Y%m%d-%H%M%S-"))
  (prefix + n.to_s).gsub(/[^a-zA-Z0-9_\-\.]+/mu, "_").gsub("-","_").gsub(/\A[_\.]+/,"").gsub(/[_\.]+\Z/,"").gsub(/_*\.+_*/,".").gsub(/_+/,"_")
end

safe_filenames = (filenames + ["", nil]).map { |fn| safe_filename(fn) }

p safe_filenames
  
