require "./xmplib"

class Debugger
	
	def initialize(interpreter)
		@nodebug=false
		begin
			@xmp=XmpConnector.new("127.0.0.1",30000)
			@xmp.Register("XO++","Interpreter")
		rescue
			puts "xmp not running... no debugger!"
			@nodebug=true
		end
		@current_instr=""
		@current_string=""
		@interpreter=interpreter
		
		@bp=false
	end

	def NewXML(attention=true)
		doc = Document.new '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><debugging></debugging>'
		if attention then
			doc.elements["debugging"].attributes["attention"]="true"
		else
			doc.elements["debugging"].attributes["attention"]="false"
		end
		return doc.root
	end
	
	
	def Refresh(string,instruction,variables,methods,objects,interpret)
		return unless @bp
		
		@current_instr=instruction #! array!
		@current_string=string
			
		root=NewXML()
		raw_string=Element.new "raw_string"
		raw_string.text=@current_string
		root.add_element raw_string
		@xmp.Send("Debugger",root)
		
		while true
			puts "waiting for debugger..."
			response=@xmp.Receive()
			#puts response
			case response.elements["response"].text
			when "step"
				puts response
				break
			when "run"
				@bp=false
				break
			when "variables","var"
				vars=NewXML()
				variables.each{|k,v|
					e=Element.new "var"
					e.attributes["name"]=k
					if variable?(v) then
						e.attributes["info"]=@interpreter.get_variable(v,variables).to_s
					elsif method?(v) then
						c=@interpreter.get_method(v,variables).getclass()
						if @interpreter.get_object(c,variables) then
							e.attributes["info"]="from "+@interpreter.get_object(c,variables).Name()
						end
					end

					e.text=v
					vars.add_element e
					
				}
				@xmp.Send("Debugger",vars)
			when "info"
				about=response.elements["response"].elements["about"].text
				a=NewXML()
				info=Element.new "info"
				info.text=@interpreter.get(about,variables).to_s
				a.add_element info
				@xmp.Send("Debugger",a)
			else
				puts "unknown: #{response.text}"
			end
		end
	end
	
	def Breakpoint()
		@bp=true if @nodebug==false
	end

end
