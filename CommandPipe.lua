--LuaCommandPipe

local CommandPipe_Handle_Label,CommandPipe_OutputFileName_Label,CommandPipe_OutputContentLastPosition_Label=1,2,3

local function New_CommandPipe_Handle(commandPipe,initial_outputFileName)
	local commandPipe_handle=io.popen('cmd /q /k'
		--	/Q: Turns echo off
		--	/K: Carries out the command specified by string but remains
		..(initial_outputFileName~=nil and '>nul' or 'prompt $+')
		--	$H: hide prompt, see `prompt /?`. 但在Output window里显示为[BS]控制字符。
		--	$_: Carriage return and linefeed. 会造成额外的换行
		--	$+: zero or more plus sign (+) characters depending upon the
    --   depth of the PUSHD directory stack, one character for each
    --   level pushed. 实际效果是无任何提示符
	,'w')
	commandPipe_handle:setvbuf('line')
	rawset(commandPipe,CommandPipe_Handle_Label,commandPipe_handle)
	rawset(commandPipe,CommandPipe_OutputFileName_Label,initial_outputFileName)
end
local Metatable_CommandPipe={} do
	function Metatable_CommandPipe.__gc(commandPipe)
		local commandPipe_handle=rawget(commandPipe,CommandPipe_Handle_Label)
		if commandPipe_handle then
			commandPipe'exit'
			commandPipe_handle:close()
			rawset(commandPipe,CommandPipe_Handle_Label,nil)
		end
	end
	function Metatable_CommandPipe.__call(commandPipe,command)--execute command, wait finish, stop
		local commandPipe_handle=rawget(commandPipe,CommandPipe_Handle_Label)
		local outputFileName=rawget(commandPipe,CommandPipe_OutputFileName_Label)
		if not command then--close / wait finish
			Metatable_CommandPipe.__gc(commandPipe)
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
		else;assert(type(command)=='string')
			assert(commandPipe_handle,'command pipe already closed')
				:write(
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
	Metatable_CommandPipe.__index=Metatable_CommandPipe.__call
end
local function CommandPipe(initial_outputFileName)
	assert(not initial_outputFileName or type(initial_outputFileName)=='string')
	local commandPipe={}
	New_CommandPipe_Handle(commandPipe,initial_outputFileName)
	setmetatable(commandPipe,Metatable_CommandPipe)
	return commandPipe
end

return CommandPipe