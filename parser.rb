require "./interpreter2"

class Parser
  def initialize()
    @command=false
    @instruction=""
    @lastchar=""
    @ignore_newline=0
    @state="none"
    @variables=Hash.new
    @methods=Hash.new
    @objects=Hash.new
    @methods.freeze
    @objects.freeze
    
    @test=Interpreter2.new
  end

  def parse(c,interpreter)

    @command=true if c=="~" and @command==false

    if @command==true then
      #puts "CHAR: #{c}" if ignore_newline
      case c
      when "\n"
        if @ignore_newline==0 then
          @command=false
          #puts ">>>>> #{instruction}"
			begin
				interpreter.Instruction(@instruction,@variables,@methods,@objects)
			#rescue Exception=>e
				#puts e
				#puts e.backtrace
			end
			@instruction=""
        else
          @instruction+=" "
        end
      when "{"
        @ignore_newline+=1
        @instruction+=" "+c +" "
        #puts "{"
      when "}"
        @ignore_newline-=1
        @instruction+=" "+c +" "
        if @ignore_newline==0 then
          @command=false
          #puts ">>>>> #{instruction}"
          interpreter.Instruction(@instruction,@variables,@methods,@objects)
          @instruction=""
          #puts "}"
        end
      when "["
        @ignore_newline+=1
        @instruction+=" "+c +" "
      when "]"
        @ignore_newline-=1
        @instruction+=" "+c +" "
      when "<"
        @ignore_newline+=1
        @instruction+=" "+c +" "
      when ">"
        @ignore_newline-=1
        @instruction+=" "+c +" "
      when "("
        @ignore_newline+=1
        @instruction+=" "+c +" "
      when ")"
        @ignore_newline-=1
        @instruction+=" "+c +" "
      when "="
        @instruction+=" "
      when "@"
        @instruction+="@ "
      else
        @instruction+=c
      end

      #~
    else
      #interpreter.what_am_i(c)
      @test.input(interpreter,c,@variables,@methods,@objects)
    end

  end

end
