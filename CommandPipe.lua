--LuaCommandPipe

local CommandPipe_Handle_Label
	,CommandPipe_OutputFileName_Label
	,CommandPipe_OutputContentLastPosition_Label
	,CommandPipe_OutputFile_Agent_Label=1,2,3,4

local function New_CommandPipe_Handle(commandPipe,outputFileName)
	local commandPipe_handle=io.popen('cmd /q /k'
		--	/Q: Turns echo off
		--	/K: Carries out the command specified by string but remains
		..(outputFileName~=nil and '>nul' or 'prompt $+')
		--	$H: hide prompt, see `prompt /?`. 但在Output window里显示为[BS]控制字符。
		--	$_: Carriage return and linefeed. 会造成额外的换行
		--	$+: zero or more plus sign (+) characters depending upon the
    --   depth of the PUSHD directory stack, one character for each
    --   level pushed. 实际效果是无任何提示符
	,'w')
	commandPipe_handle:setvbuf('line')
	rawset(commandPipe,CommandPipe_Handle_Label,commandPipe_handle)
	if outputFileName=='' then--handle filename internally
		outputFileName='.'..os.tmpname()..'.tmp'
		--	tmpname '\\xxxx' > '.\\xxxx'
		rawset(commandPipe,CommandPipe_OutputFile_Agent_Label,true)
	end
	rawset(commandPipe,CommandPipe_OutputFileName_Label,outputFileName)
end
local function Close_CommandPipe_Handle(commandPipe)
	local commandPipe_handle=rawget(commandPipe,CommandPipe_Handle_Label)
	if io.type(commandPipe_handle)=='file' then
		commandPipe'exit'
		commandPipe_handle:close()
	end
	if commandPipe_handle then
		rawset(commandPipe,CommandPipe_Handle_Label,nil)
	end
end
local Metatable_CommandPipe={} do
	function Metatable_CommandPipe.__gc(commandPipe)
		Close_CommandPipe_Handle(commandPipe)
		local commandPipe_OutputFile_Agent=rawget(commandPipe,CommandPipe_OutputFile_Agent_Label)
		if commandPipe_OutputFile_Agent then
			local outputFileName=rawget(commandPipe,CommandPipe_OutputFileName_Label)
			assert(os.remove(outputFileName),'cant remove tmpfile for recieving output.')
			rawset(commandPipe,CommandPipe_OutputFileName_Label,nil)
		end
	end
	function Metatable_CommandPipe.__call(commandPipe,command)--execute command, wait finish, stop
		local commandPipe_handle=rawget(commandPipe,CommandPipe_Handle_Label)
		local outputFileName=rawget(commandPipe,CommandPipe_OutputFileName_Label)
		if not command then--close / wait finish
			Close_CommandPipe_Handle(commandPipe)
			local output_file_content
			if outputFileName then--read output file content
				local output_file_handle=io.open(outputFileName)
				assert(output_file_handle)
				local commandPipe_OutputContentLastPosition=rawget(commandPipe,CommandPipe_OutputContentLastPosition_Label)
				output_file_handle:seek('set',commandPipe_OutputContentLastPosition)
				output_file_content=output_file_handle:read'a'
				commandPipe_OutputContentLastPosition=output_file_handle:seek'cur'
				rawset(commandPipe,CommandPipe_OutputContentLastPosition_Label,commandPipe_OutputContentLastPosition)
				output_file_handle:close()
			end
			if command==nil then--restart
				New_CommandPipe_Handle(commandPipe,outputFileName)
			else--reset
				if outputFileName then
					io.open(outputFileName,'w'):close()
					rawset(commandPipe,CommandPipe_OutputContentLastPosition_Label,0)
				end
			end
			return output_file_content
		else;assert(type(command)=='string','command should be string')--execute command
			assert(io.type(commandPipe_handle)=='file','command pipe already closed')
			commandPipe_handle:write(
					(outputFileName
						and '3>>'..outputFileName..' 1>>&3 2>>&3 '
						or '')
					..command..'\n')
				:flush()
			return commandPipe
		end
	end
	function Metatable_CommandPipe.__concat(commandPipe,b)
		print"deprecate. for `commandPipe..string..string_b` would be `commandPipe..stringstring_b`"
		assert(type(commandPipe)=='table' and getmetatable(commandPipe)==Metatable_CommandPipe)
		return commandPipe(b)
	end
	function Metatable_CommandPipe.__index(self,command)
		self(command)
		return self()
	end
end
local function CommandPipe(outputFileName)
	assert(not outputFileName or type(outputFileName)=='string')
	local commandPipe={}
	New_CommandPipe_Handle(commandPipe,outputFileName)
	setmetatable(commandPipe,Metatable_CommandPipe)
	return commandPipe
end

return CommandPipe