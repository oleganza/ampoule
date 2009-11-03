
filenames = %{
  
  file.txt
  Screen shot 2009-11-03 at 9.00.09 .png
  "quotes'every'where"
  /crazy\\slashes/\\
  ......dots....
  .htaccess
}.strip.split("\n")

def safe_filename(n, prefix = Time.now.strftime("%Y%m%d-#{rand(2**64)}-"))
  (prefix + n.to_s).gsub(/[^a-zA-Z0-9_\-\.]+/mu, "_").gsub("-","_").gsub(/\A[_\.]+/,"").gsub(/[_\.]+\Z/,"").gsub(/_*\.+_*/,".").gsub(/_+/,"_")
end

# blah.html => f86536be7c5a8e728472ef6baae86c87c.hmtl
def safe_filename(n)
  sfx = $1 if n =~ /(\.\w+)$/
  "#{rand(2**128).to_s(16)}#{sfx}"  
end


safe_filenames = (filenames + ["", nil]).map { |fn| safe_filename(fn) }

p safe_filenames

def pretty_file_size(bytes)
  kbs = bytes / 1024.0
  mbs = kbs / 1024.0
  return "%.1f Mb" % mbs if mbs > 0.9
  return "%.1f Kb" % kbs if kbs > 0.9
  "#{bytes.to_i} bytes"
end
  
20.times do
  bytes = 2.0**(30*rand)
  p [bytes, pretty_file_size(bytes)]
end
