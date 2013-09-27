#!/usr/local/bin/ruby
# coding: UTF-8
# 
##############Notizen################################
# - bei den ganzen ~? vergleichen muss vorher nicht aufgelöst werden,
#   da sonst ein vergleich von arrays/maps nicht möglich wäre
#

require "./debugger"

def findInner(string,char1,char2)
	#puts "findInner: string: #{string.to_s}"
	i1,i2=string.index(char1),string.index(char2)
	string.length.times{|index|
		case string[index]
		when char2
      #puts "find: #{i1}-#{index}"
			return i1,index
		when char1
			i1=index
		else
		end
	}
	#puts "konnte keine inneren klammern finden!"
	return nil,nil
end


class XMethod
	attr_accessor :Code
	def initialize()
		@Code=Array.new
    @classmember=""
	end
  def print()
    puts "XMethod: "
    @Code.each { |item|
      "- #{item}\n"
    }

  end
  def to_s
	puts "blaaaa"
	string=@Code.each{|item|
		"- #{item}\n"
	}
	puts string
	return string
  end
  def classmemberof(c)
    @classmember=c
  end
  def classmember?()
    return @classmember!=""
  end
  def getclass()
    return @classmember
  end
	def AddCommand(command,variables)
		case command[0,1]
		when "~" 
			@Code<<command
		#when "*" 
		#	puts "---"
		#	@Code<<variables[command[1,command.length-1]]
		when "|"
			#! wofür ist das hier?
			@Code.last()<<" #{command[1,command.length-1]}"
		else
			if @Code.last()==nil then
				puts command
			end
			@Code.last()<<" #{command}"
		end
	end
  def copyfrom(method)
    
    method.Code.each{|e|
      @Code<<e
    }
    #newm.classmember_of(@classmember)
    
  end
end
class XVariable
	attr_accessor :map
	def initialize()
		@map=Hash.new
	end
	def Set(value)
		@map.clear
		@map["0"]=value
	end
	def Get
		return @map["0"]
	end
	def Plus(value)
		new=XVariable.new
		#puts "Plus: #{@map["0"].to_i}+#{value.to_i()}"
		result=(@map["0"].to_i())+(value.to_i())
		new.Set(result.to_s)
		return new
	end
	def AddToArray(value)
		@map[@map.keys.count.to_s]=value
	end
  def RemoveFromMap(name)
    #@map[name]=nil
    @map.delete(name)
  end

	def AddToMap(name,value)
		#puts "AddToMap: #{name} => #{value}"
		#@map[name]=value
    raise "ERROR: AddToMap-> value is from type: #{value.class}" if value.class!=String
		@map[name]=XVariable.new
		@map[name].Set(value)
		#puts @map.to_s
		
	end
	def ==(other)
		#puts "#{self}==#{other}"
		ret=false
		if other==nil then
      return ret
		end
		#!hier fehlen noch vergleiche f端r maps bzw arrays...
		#! erst die maps.keys mit sort sortieren und dann vergleichen!
    if @map.keys.count==other.map.keys.count then
			if @map.keys.count==1 then
        if @map["0"].to_s==other.map["0"].to_s then
          ret= true
				end
			end
		end
		
		return ret
	end

  def copyfrom(var)
    
    var.map.each_pair{|k,v|
      @map[k]=v
    }
  end
	def to_s()
		return (@map.values).join(" ")
	end
	def to_i()
		#!端berpr端fen ob vorhanden!
		
		return @map["0"].to_i
	end
	
end
class XObject
	attr_accessor :id, :Name, :Variables, :interpreter, :description
	def initialize(interpreter)
		@id=0
		@Name
		@Variables=Hash.new
		@parents=Hash.new
		@chils=Hash.new
		@interpreter=interpreter
		@type="" #vllt lieber ne liste?
		@description=""
		
		
	end
	def freeze()
		@Variables.freeze()
	end
	def add_method(name,mem)
	  #! hier müssen alle beziehungen zu parents und chils überprüft werden!
    #! hier darf nicht kopiert werden! einfach nur nen link setzten!
    #! oder doch kopieren?
    raise "ERROR: name ist leer" if name==nil or name==""
    raise "ERROR: mem ist leer" if mem==nil or mem==""
    
    raise "argh" if name=="+" and @Name!="Std"
    @Variables[name]=mem
    @interpreter.get_method(mem,@Variables).classmemberof(id)
    
    
	end
  def add_variable(name,mem)
	raise "argh" if name=="+" and @Name!="Std"
	  #! hier müssen alle beziehungen zu parents und chils überprüft werden!
    @Variables[name]=mem
  end
  def copyfrom(obj)
    #puts "copyfrom(obj) aufgerufen"
    
    @interpreter=obj.interpreter
    @Variables=Hash.new

    obj.Variables.each_pair{|key,value|
		raise "argh" if key=="+" and @Name!="Std"
      case @interpreter.get_type(key,obj.Variables)
      when "v"
        @Variables[key]=@interpreter.copy_variable(key,obj.Variables)
      when "m"
        @Variables[key]=@interpreter.copy_method(key,obj.Variables)
        @interpreter.get_method(key,@Variables).classmemberof(@id)
      when "o"
        @Variables[key]=@interpreter.copy_object(key,obj.Variables)
      when "e"
        raise "Beim kopieren ist ein Fehler aufgetreten"
      end
      
    }
    
  end

  def new_child(id)
    puts "#{@Name} new child: #{id}"
  end
  def inherit(id)
    #somethink
  end
	
	def to_s
		info=""
		info+="Name: #{@Name}\n"
		info+="id: #{id}\n"
		info+="Variables:\n"
		@Variables.each{|v,k|
			info+="  #{v} -> #{k}\n"
		}
		return info
	end
end


class Interpreter
  attr_accessor :objects,:methods
	def initialize()
		@objects=Hash.new
		@id_counter=0
		@namecounter=0
		@state="none"
		@memory=Hash.new
		@methods=Hash.new
		
		@debugger=Debugger.new (self)
		
			
		@v_keywords=Array.new ["CURRENT_OBJECT","RETURN"]
		
		@global=Hash.new
		@v_keywords.each{|e|
			#@global << e
		}
		
	end
	def ID()
		return @id_counter+=1
	end
	def TmpName(prefix)
		@namecounter+=1
		return ("#{prefix}#{@namecounter}")
	end



  def new_method(name,methods)
    #puts "new_var: #{name}"
    tmpname=TmpName("METHOD")
    name=tmpname if name==nil or name=="" #new
    methods[name]=tmpname if methods!=nil
    #variables[name]=XVariable.new #old
    @methods[tmpname]=XMethod.new
    return name
  end
  def get_method(name,methods)
	return get(name,methods,"m")
  end
  
  def run_method(name,variables,newvariables)
    #puts "run_method #{name} obj: #{get_method(name,methods)}"
    #get_method(name,methods).print()
    if get_method(name,variables)==nil then
		raise "Error konnte Methode name: #{name} nicht auflösen"
		
    end
    get_method(name,variables).Code.each{|command|
      #puts "command: #{command}"
        Instruction(command,newvariables,nil,nil)
      }
  end
	def var(name,variables)
		return get_variable(name,variables)
	end
  #! def set_ref oder so muss es noch geben, falls man zeiger umbiegen möchte..
  def set_var(name,data,variables)
    #! hier fehlt noch die rekursion wie bei get_variable?
    #variables[name]=data #old
    return if name==nil
    if data==nil then
      data=XVariable.new
    end
    raise "ERROR: Data muss vom Typ XVariable sein  data.class= #{data.class}" if data.class != XVariable
    if(name.class != String)then
      #puts "ERROR: Type of name: #{name.class} XVariable: #{name.to_s}"
      if name.class==XVariable then
        raise "WARNING: Es wird ne XVariable als name übergeben!"
        name=name.to_s
      end
    end
    
    if @memory.key?(name) then
      @memory[name]=data
    else
      if variables.key?(name) then
        @memory[variables[name]]=data
      else
        raise "WARNING: #{name} kann nicht aufgelöst werden"
      end
    end
    #set_var(variables[name],data,variables)
     #get irgendwie nich..
  end
  def get_variable(name,variables)
    return get(name,variables,"v")
  end

  def new_var(name,variables)
    #puts "new_var: #{name}"
    tmpname=TmpName("VARIABLE")
    name=tmpname if name==nil or name=="" #new
    variables[name]=tmpname if variables!=nil
    @memory[tmpname]=XVariable.new
    return name
  end
  
  def print_variables(variables)
    variables.each_pair{|key,value|
      puts "key: #{key} value: #{value} memory: #{var(key,variables).to_s}"
    }
  end

  def new_object(name,objects)
    tmpname=TmpName("OBJECT")
    name=tmpname if name==nil or name=="" #new
    #description
	objects[name]=tmpname if objects!=nil
	    
    @objects[tmpname]=XObject.new(self)
    @objects[tmpname].Name=name
    @objects[tmpname].id=tmpname
    
    return name
  end
  def copy_variable(name,variables)
    tmpname=new_var(nil,nil)
    #puts "var: #{name}"
    var(tmpname,nil).copyfrom(var(name,variables))
    return tmpname
  end
  def copy_method(name,methods)
    tmpname=new_method(nil,nil)
    get_method(tmpname,nil).copyfrom(get_method(name,methods))
    return tmpname
  end
  def copy_object(name,objects)
    tmpname=new_object(nil,nil)
    get_object(tmpname,nil).copyfrom(get_object(name,objects))
    return tmpname
  end
	def get_object(id,objects)
		return get(id,objects,"o")
	end
  def get_object_addr(id,objects)
    @objects.each_pair{|key,value|
      return key if value==get_object(id,objects)
    }
    return nil
  end
  def get_method_addr(method,methods)
    @methods.each_pair{|key,value|
      return key if value==get_method(method,methods)
    }
    return nil
  end
  def get_variable_addr(variable,variables)
    @memory.each_pair{|key,value|
      return key if value==var(variable,variables)
    }
    return nil
  end
  def get_type(element,variables)
    #puts "get_type: typ von >#{element}< bestimmen"
    #puts "SOLLTE GEHEN" if variables.include?(element)
    return "e" if variables[element]==nil
    p=variables[element]
    #puts "get_type: element <#{element}> konnte nicht bestimmt werden" if p==nil
    return "v" if variable?(p)
    return "o" if object?(p)
    return "m" if method?(p)
  end

	def get(name,variables,type="any")
	
		raise "ERROR: name ist nil" if name==nil
		raise "ERROR: Type of name: #{name.class}" if(name.class != String)
		#raise "ERROR: variables is nil" if variables==nil
		
		if(variables and variables.key?(name)) then
			#immerhin im variablenraum...
			id=variables[name]
		else
			id=name
		end
		
		mem= nil
		mem= @objects if object?(id) and (type=="any" or type=="o")
		mem= @memory if variable?(id) and (type=="any" or type=="v")
		mem= @methods if method?(id) and (type=="any" or type=="m")
		
		#raise "Konnte den Typ nicht bestimmen: #{name} #{variables}" unless mem
		return nil unless mem
		
		return mem[id] if mem.key?(id)
		
		raise "ERROR: Konnte #{name} nicht auflösen"
	
	end

  
	def Instruction(string,variables,methods,objects,interpret=true)
    variables.each_pair{|key,value|
      raise "variables should contain Strings only!" if value.class != String
      raise "variables should contain Strings only!" if key.class != String
    }
    
    	
	begin
		variables.merge!(get_object("CURRENT_OBJECT",variables).Variables)
	rescue
		#puts "Es gibt vermutlich kein Current Object"
	end
	
	@global.each{|k,v|
		variables[k]=v
		if k=="Std" then
			begin
			get_object(v,variables).Variables.each{|k,v|
				variables[k]=v unless variables.key?(k)		
			}
			rescue
				#puts "konnte #{v} nicht finden"
			end
		end
	}
    methods=nil
    objects=nil
   
	instruction=string.split
	parameter=instruction[1,instruction.length-1]

    interpret=false if instruction[0]=="~c" or instruction[0]=="~comment"
    
		if (interpret==true) then
      #anonyme methoden:
      #puts "PARAMETER BEFORE #{parameter.to_s}"
      #dies muss zuerst geschehen, damit die ganzen *variablen nicht aufgelöst werden
      #puts parameter.to_s
      i1,i2=findInner(parameter,"{","}")
      while i1!=nil
        data=parameter.slice!(i1..i2)
        data.delete("{")
        data.delete("}")
        #puts "METHODE: "+data.to_s
        if not data.empty? then

          #methodname=TmpName()
          methodname=new_method("",variables)
          Instruction("~addMethod #{methodname} #{data* " "}",variables,methods,objects,false)# hier darf nicht interpretiert werden
          parameter.insert(i1,methodname)

        end
        #######################
        i1,i2=findInner(parameter,"{","}")
      end

      ##Klammern (Verschachtelung):
      i1,i2=findInner(parameter,"(",")")
      while i1!=nil
        data=parameter.slice!(i1..i2)
        data.delete("(")
        data.delete(")")

        if not data.empty? then
          #mapname=TmpName()
          #Instruction("~map #{mapname}",variables)
          mapname=new_var("",variables)
          #puts "data.join: #{data.join(" ")}"
          #c="~call #{mapname} #{data.join(" ")}" # if call looks like: ~call return para method
          #c="~call #{data[0]} #{mapname} #{data.slice(1,data.length-1).join(" ")}" # if call looks like: ~call method return para
          paraname=data.slice(1,data.length-1).join(" ")
          if paraname=="" then
            paraname=new_var("",variables)
          end
          c="~call #{data[0]} #{paraname} #{mapname} " # if call looks like: ~call method  para return
          #puts c
          #begin
          Instruction(c,variables,methods,objects)
          #rescue => e
          #  raise "ERROR: Beim ()aufruf einer Methode trat ein Fehler auf! \n Aufruf: ~call #{data[0]} #{paraname} #{mapname} \n Error: #{e}"
          #end
          parameter.insert(i1,mapname)
          #puts "parameter: #{parameter.to_s}"
        end
        i1,i2=findInner(parameter,"(",")")
      end


      #puts "PARAMETER AFTER #{parameter.to_s}"
      #puts "1: "+parameter.to_s

      #einzelne "*" zum nachfolger hinzufügen
      while parameter.include?("*")
        index=parameter.index("*")
        parameter[index+1]="*#{parameter[index+1]}"
        parameter.delete_at(index)
      end
      #einzelne "#" zum nachfolger hinzufügen
      while parameter.include?("#")
        index=parameter.index("#")
        parameter[index+1]="##{parameter[index+1]}"
        parameter.delete_at(index)
      end
      parameter=parameter.collect{|p|
        case p[0,1]
        when "*"
          #variables[p[1,p.length-1]].to_s
          #mem(p[1,p.length-1],variables)
          if p[1,p.length-1].include? "." 
            object=p[1,p.length-1].split(".")[0] #!! auch die object-aufloese methode benutzen!!!!
            method=p[1,p.length-1].split(".")[1]
            if get_object(object).Methods.include?(method)#get_method(method,get_object(object).Methods)!=nil
              get_method_addr(method,get_object(object).Methods)
            end
          elsif variables.include?(p[1,p.length-1])
              variables[p[1,p.length-1]]
          else
            #variables[p[1,p.length-1]]
            #
            #puts "variables: #{variables}"
            raise "ERROR: #{p[1,p.length-1]}  konnte nicht aufgelöst werden. instruction: #{string}"
            nil
          end
        when "#"
          #puts "<#{p[1,p.length-1]}> wird aufgelöst"
          var(p[1,p.length-1],variables).to_s
        else
          p
        end
      }
      ## unbekannte datentype, daher alle übernehmen:


      #puts parameter.to_s

  #! ~comment wenn arrays und maps ineinander verschachtelt werden geht es irgendwie nich -.-
  #! ~comment find inner muss also immer beide dinger berücksichtigen (<> und [])
  #! ~comment call ClearMap < [hallo=0 du=1 da=2] >
  #! das muss echt unbedingt gemacht werden..
      ##------Anonyme arrays------#
      i1,i2=findInner(parameter,"<",">")
      while i1!=nil
        mapdata=parameter.slice!(i1..i2)
        mapdata.delete("<")
        mapdata.delete(">")

        #mapname=TmpName()
        #Instruction("~map #{mapname}",variables)
        mapname=new_var("",variables)

        if not mapdata.empty? then
          (mapdata.length).times{|i|
            value=mapdata[i]
            Instruction("~addToMap #{mapname} #{i} #{value}",variables,methods,objects)
          }
        end
        parameter.insert(i1,mapname)
        i1,i2=findInner(parameter,"<",">")
      end

    
      i1,i2=findInner(parameter,"[","]")
      #puts parameter.to_s
      while i1!=nil
        mapdata=parameter.slice!(i1..i2)
        #puts "DATA: "+mapdata.to_s
        mapdata.delete("[")
        mapdata.delete("]")
        #puts "DATA: "+mapdata.to_s

        #mapname=TmpName()
        #Instruction("~map #{mapname}",variables)
        mapname=new_var("",variables)

        if not mapdata.empty? then
          (mapdata.length/2).times{|i|
            name=mapdata[i*2]
            value=mapdata[i*2+1]
            Instruction("~addToMap #{mapname} #{name} #{value}",variables,methods,objects)
            #puts "~addToMap #{mapname} #{name} #{value}"
          }
        end
        parameter.insert(i1,mapname)
        i1,i2=findInner(parameter,"[","]")
      end
      #puts instruction.to_s
    end
		#~ 
		parameter.freeze
	
	
	@debugger.Refresh(string,instruction,variables,methods,objects,interpret)
		
    case instruction[0]
		when "~object"
      object=parameter[0]
     
      new_object(object,variables)
      
	when "~global"
		@global[parameter[0]]=variables[parameter[0]]
		
	when "~print"
		parameter.length.times{|p|
	  print parameter[p]+" " unless parameter[p]==nil
	}
	puts
    when "~put"
			parameter.length.times{|p|
          print parameter[p]+" " unless parameter[p]==nil
		}
      #puts "DEPRECATED"
      #! das muss durch die ToString Methode ersetzt werden, die immer einen kompletten string zurückliefert, der dann auch mit print angezeigt werden kann
  	when "~call"
		#puts "--> #{parameter[0]}"
		#puts "call inst: "+instruction.to_s
		#puts "call para: "+parameter.to_s
		code=nil
		  
		#puts "#{newmethods}"
		newvariables=Hash.new
		  
		#newvariables.merge!(variables) #das geht irgendwie nich.. is vllt aber auch besser so, damit man nur auf die variable zugreifen kann die im selben namespace liegen
		#puts variables
		object,method=object_path(parameter[0],variables)
		  
	  
		choice=-1
		if object
			choice=0
			code=object.Variables[method]
			newvariables["CURRENT_OBJECT"]=object.id

		else
			if get_method(parameter[0],variables)!=nil then
			  #puts "2"
				#puts methods
				choice=2
				code=parameter[0]
			  #code=get_method_addr(parameter[0],variables)
			else
				puts variables
			  raise "ERROR: Die Methode >#{parameter[0]}< kann nicht aufgerufen werden"
			end
		end
		puts "AARG: (choice=#{choice})#{parameter[0]} objcet: #{object} method: #{method}" if code==nil 
      
      
      if parameter[1]!=nil then
        #puts "parameter sind gesetzt!"
        #if(var(variables[parameter[1]],variables)==nil)then
		if(var(parameter[1],variables)==nil)then
			raise "Error: konnte Parameter #{parameter[1]} nicht auflösen"
		end
        var(parameter[1],variables).map.each_pair{|key,value|
          newvariables[key]=value.to_s
        }
      end
      

      
      if get_method(code,variables).classmember?()
		#EIG. kann das doch raus, da alle Variable beim begin der instruction hinzugefügt
		#werden wenn es ein CURRENT_OBJECT gibt...
		# funktioniert aber irgendwie nicht ohne :(
        newvariables.merge!(get_object(get_method(code,variables).getclass(),variables).Variables)
      end

      #newvariables["Std"]=variables["Std"]
      variables.each_pair{|k,v|
        #puts "k: #{k} v: #{v}"
        #! muss hier nicht das CURRENT_OBJECT ausgeschlossen werden? wird ja oben gesetzt und hier evtl wieder überschrieben!
        newvariables[k]=v if(object?(v))
      }
		newvariables["Std"]=variables["Std"] if variables.key?("Std")
      run_method(code,variables,newvariables)
      
	  	set_var(parameter[2],var("METHOD_RETURN",newvariables),variables)
	  	
  		
      #puts "RETURN memory: #{var(parameter[2],variables)} "
      #puts "<-- #{parameter[0]}"
  	when "~return"
      new_var("METHOD_RETURN",variables)
      set_var("METHOD_RETURN",var(parameter[0],variables),variables)
      #puts "Returnvalue set to #{variables["RETURN"]} memory: #{var(variables["RETURN"],variables)}"
  	
    when "~var"
        object,variable=object_path(parameter[0],variables)
        new_var(variable,variables)
               
        object.add_variable(variable,variables[variable]) if object
        #object.add_variable(variable,get_variable_addr(variable,variables)) if object
          	
   	when "~addMethod"
   	
        #WIRD INTERN BENUTZT!
  		#die parameter werden nicht aufgelöst, da hier durch instruction durchiteriert wird.
  		#puts "~addMethod"+instruction.to_s
		m=methods
		(instruction[2..instruction.length]).each{|command|
			get_method(instruction[1],m).AddCommand(command,variables)
		}
	when "~method"
		#puts parameter.to_s
		object,method=object_path(parameter[0],variables)
		#get_object(object,objects).add_method(method,methods[parameter[1]])
		object.add_method(method,variables[parameter[1]])

	when "~addToMap"
      #puts "~addToMap map: #{parameter[0]} par0: #{parameter[1]} par1: #{parameter[2]}"
      #print_variables(variables)
  		var(parameter[0],variables).AddToMap(parameter[1],parameter[2])
  			

  	when "~count"
      #puts "~count #{parameter[0]} #{parameter[1]}"
      #print_variables(variables)
  		var(parameter[1],variables).map.clear
  		var(parameter[1],variables).Set(var(parameter[0],variables).map.keys.count)
  	when "~getFromMap"
      
			var(parameter[2],variables).map.clear
  		#set_var(parameter[2],(var(parameter[0],variables).map[parameter[1]]),variables)
      var(parameter[2],variables).Set(var(parameter[0],variables).map[parameter[1]])
    when "~removeFromMap"
      #puts "~removeFromMap nr: #{parameter[1]} map: #{var(parameter[0],variables).to_s}"
      var(parameter[0],variables).RemoveFromMap(parameter[1])
  	when "~keys"
  		var(parameter[1],variables).map.clear
  		var(parameter[0],variables).map.keys.each{|key|
  			var(parameter[1],variables).AddToArray(key)
  		}
	when "~exit"
		puts "exit!"
		exit(1)
    ##-------------OBJECTS-------------##
    when "~ref"
      #raise "ERROR: Das Object(#{parameter[0]}) auf den die Ref(#{parameter[1]}) zeigen soll ist unbekannt!" unless variables.key?(parameter[0])
      
      object,ref=object_path(parameter[1],variables)
      if object then
		object.Variables[ref]=var(parameter[0],variables)
      else
        variables[parameter[1]]=variables[parameter[0]]
      end
    when "~new"
		
    	
      #raise "ERROR: Das Object(#{parameter[0]}) das neu erstellt werden soll existiert nicht" unless variables.key?(parameter[0])
      space=nil
            
      object,ref=object_path(parameter[1],variables)
      
		if object then
			object.Variables[ref]=copy_object(parameter[0],variables) #! das über ne methode machen!
			space=get_object(ref,object.Variables).Variables
		else
			variables[parameter[1]]=copy_object(parameter[0],variables)
			space=get_object(parameter[1],variables).Variables
		end
		if( get_method("CONSTRUCTOR", space)!=nil) then
			Instruction("~call #{ref}.CONSTRUCTOR #{parameter[2]} #{parameter[3]}",variables,methods,objects)
		end
      
    ##-------------/OBJECTS-------------##
    ##-------------PARAMETER-------------##
    when "~exist"
      if var(parameter[0],variables)!=nil then
        set_var(parameter[0],var(parameter[1],variables),variables)
      end
    when "~nexist"
      #if var(parameter[0],variables)==nil then
      if variables[parameter[0]]==nil then
        #set_var(parameter[0],var(parameter[1],variables),variables)
        new_var(parameter[0],variables)
        set_var(parameter[0],var(parameter[1],variables),variables)
      end
    when "~adapt"
      #! in parameter 3 evtl fehler etwas reinschreiben wenn keiner von beiden existiert?
      #puts "~adapt #{parameter[0]} #{parameter[1]}"
      #print_variables(variables)

      if variables.include?(parameter[0])
        variables[parameter[1]]=variables[parameter[0]]
      elsif variables.include?(parameter[1])
        variables[parameter[0]]=variables[parameter[1]]
      else
        #raise "ERROR: ~adapt #{parameter[0]} #{parameter[1]}"
        variables[parameter[0]]=new_var("",variables)
        variables[parameter[1]]=new_var("",variables)
      end


    when "~require"
      if var(parameter[0],variables)==nil then
        #! FEHLER WERFEN
        puts "BLUB"
        puts "Bulb"
      end
    ##-------------/PARAMETER-------------##
    ##-------------COMPARE-------------##
    when "~?l"
      if var(parameter[0],variables) < var(parameter[1],variables) then
        Instruction("~call #{parameter[4]} #{parameter[3]} #{parameter[2]}",variables,methods)#
      end
    when "~?ne"
      unless var(parameter[0],variables) == var(parameter[1],variables)  then
        #puts "~call #{parameter[4]} #{var(parameter[4],variables)} #{parameter[3]} #{parameter[2]}"
        Instruction("~call #{parameter[4]} #{parameter[3]} #{parameter[2]}",variables,methods,objects)#
      end
    when "~?eq"
      #puts "~?eq p0: #{parameter[0]} #{var(parameter[0],variables).to_s}   p1: #{parameter[1]} #{var(parameter[1],variables).to_s} call: #{parameter[4]} "
      #raise "par0" if var(parameter[0],variables)==nil
      #raise "par1" if var(parameter[1],variables)==nil
      if var(parameter[0],variables)==var(parameter[1],variables)  then
        Instruction("~call #{parameter[4]} #{parameter[3]} #{parameter[2]}",variables,methods,objects)#
      end
    ##-------------/COMPARE-------------##

    ##-------------OPERATIONS-------------##
    when "~+!"
      set_var(parameter[0],var(parameter[0],variables).Plus(var(parameter[1],variables)),variables)

    ##-------------/OPERATIONS-------------##
    when "~debuginfo"
      puts "Methods: "
      @methods.each_pair{|key,value|
        puts "#{key} ->"
        value.print
      }
      puts "Variables: "
      @memory.each_pair{|key,value|
        puts "#{key} -> #{value.to_s}"
        
      }
    when "~bp"
		@debugger.Breakpoint()
	when "~freeze"
		get_object(parameter[0],variables).freeze()
    when "~c"
  	when "~comment"
  			#just ignore... 	
    when "~"
      parameterstring=""
  		test= parameter.each{|p|
  			parameterstring+=" #{p}"
			" #{p}"
  		}
  		#! hübsch machen! einfach test (Array) to string zusammenbauen und gut is...
  		#puts "#{parameterstring} -> #{test.toString} ist fast das gleiche!"
      Instruction("~call #{parameterstring}",variables,nil,nil)
		else
  			puts "unknow instruction: #{instruction.to_s}"
		end
		
		#CheckObjects(instruction,variables)
	end
	
end

def object_path(str,variables)
	if str.include? "." then
		#! hier mit ner schleifer alle *.* durchgehen damit sowas geht: object.blub.aaa.bbb
		first=str.split(".")[0]
		second=str.split(".")[1] #may be a var,meth or another object...
		
		if first=="this" then
			#first=var("CURRENT_OBJECT",variables).Get
			first=variables["CURRENT_OBJECT"]
			puts "CURRENT_OBJECT not set" if first==nil
			#first=variables["GLOBAL"] if first==nil
			#puts "---------> #{first}"
		end
		#begin
			object=get_object(first,variables)
		#rescue
		#	puts "ARG"
		#	puts variables.keys
		#end
		return object,second 
    else
		#return @global_object.Variables[str],str if @global_object.Variables.key? str
		begin
			return get_object(str,variables),str
		rescue
			return nil,str
		end
    end
end
def variable?(name)
  return true if name[0..7]=="VARIABLE"
  return false
end
def method?(name)
  return true if name[0..5]=="METHOD"
  return false
end
def object?(name)
  return true if name[0..5]=="OBJECT"
  return false
end
