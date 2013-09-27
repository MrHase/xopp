require "rexml/document"
require "./interpreter.rb"
require "./parser.rb"
include REXML


if ARGV[0]==nil then
	puts "no file..."
	exit
end

ARGV.each do|a|

  puts "Argument: #{a}"

end

require 'rexml/document'
include REXML
begin
file = File.new(ARGV[0])
rescue
	puts "no file: #{ARGV[0]}"
	exit
end
puts "los gehts"
doc = Document.new(file)
root=doc.root

project=root.elements["project"]
app=project.elements["application"]
interpreter=Interpreter.new
parser=Parser.new()
#bibs laden
app.elements.each{|e|
	if e.name=="include" then
    f=File.new( e.attributes["file"])
    f.each_char { |chr|
      parser.parse(chr, interpreter)
    }
    f.close
  end
}

#app ausführen
f=File.new( app.attributes["file"])
    f.each_char { |chr|
      parser.parse(chr, interpreter)
    }
f.close

#puts doc
