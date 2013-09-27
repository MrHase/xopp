require "./interpreter"
class Stack
	def initialize
		@stack=Array.new
	end
	def +(obj)
		@stack.push obj
		
	end
	def -(obj)
		return @stack.pop
	end
	def Current
		return @stack.last
	end
end

class Interpreter2

	def initialize
		@stack=Stack.new
	end
	def input(interpreter, char,variables,methods,objects)
		if @stack.Current==nil
			#! DA WIR HIER DEN PARSER NICHT BENUTZEN MUSS VOR UND NACH JEDEM <,>,{,},[,] EIN LEERZEICHEN!
			#! RANDOM NAME der aber nicht 2 mal vergeben werden darf!!!
			#! unbedingt machen
			#! evtl darf space doch ein character werden?
			return if char==" " or char=="\n" # space und return dürfen keine objecte werden
			begin
				obj_name= "XXX" #!!!
				puts "neus Object anlegen, da stack leer: #{char}"
				interpreter.Instruction("~new String #{obj_name} < < #{char} > >",variables,methods,objects)
				@stack+ obj_name
				
			rescue Exception=>e
				puts e.backtrace
				puts "Non Critical Error? : #{e}"
			end
		else
			begin 
				case char
				when " "
					interpreter.Instruction("~call #{@stack.Current}.SPACE",variables,methods,objects)
				when "\n"
					interpreter.Instruction("~call #{@stack.Current}.RETURN",variables,methods,objects)
					@stack- nil
				else
					interpreter.Instruction("~call #{@stack.Current}.CONCAT < < #{char} > >",variables,methods,objects)
				end
			rescue Exception=>e
				puts e.backtrace
				puts "Non Critical Error? : #{e}"
			end
		end
	end



end
