require "../xmplib"
xmp=XmpConnector.new("127.0.0.1",30000)
xmp.Register("XO++","Debugger")



def SendSimpleCommand(xmp,cmd)
	doc = Document.new '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><debugging></debugging>'
	root=doc.root
	r=Element.new "response"
	r.text=cmd
	root.add_element r
	xmp.Send("Interpreter",root)
end

while true
	msg=xmp.Receive
	#puts "msg: #{msg}"
	current_string=msg.elements["raw_string"].text
	puts "raw: #{current_string}"
	#puts ": #{}"
		
	while true
		puts "\n"
		print "cmd: "
		raw = $stdin.gets.chomp
		cmd=raw
		case cmd
		when "step","run"
			SendSimpleCommand(xmp,cmd)
			break
		when "raw","raw_string"
			puts msg.elements["raw_string"].text
		when "variables", "var"
			SendSimpleCommand(xmp,cmd)
			t_msg=xmp.Receive()
			t_msg.elements.each{|e|
				# e.name=="var"
				str="#{e.attributes["name"]} -> #{e.text}"
				spaces=50
				spaces.times{str<<" "}
				str.insert(spaces,": #{e.attributes["info"]}")
				puts str
			}
		when "current","pos"
			puts "raw: #{current_string}"
		when /info .*/
			doc = Document.new '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><debugging></debugging>'
			root=doc.root
			r=Element.new "response"
			r.text="info"
			a=Element.new "about"
			a.text=cmd.split()[1]
			r.add_element a
			root.add_element r
			xmp.Send("Interpreter",root)
			t_msg=xmp.Receive()
			puts t_msg.text
		else
			puts "unknown command: #{cmd}"
		end
	end
	

end
