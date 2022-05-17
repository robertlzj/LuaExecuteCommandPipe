--test.lua
local socket=select(2,pcall(require,'socket'))
local gettime=socket and socket.gettime or os.time
local sleep=socket and socket.sleep or function(time_in_sec) os.execute('ping 192.0.2.2 -n 1 -w '..(time_in_sec*1000)..' > nul') end

local Output_File_Name='test_output.txt'
--	assert(not io.open(Test_File_Name),'caution overwrite!')
io.open(Output_File_Name,'w'):close()--new
local output_content
local function get_output()
	local output_file_handle=io.open(Output_File_Name)
	local output_file_content=output_file_handle:read'a'
	output_file_handle:close()
	return output_file_content
end

local CommandPipe=require'CommandPipe'

if print'Test basic use:'
	or true
	then
	local output_method=nil
		--	nil: stdout, false: nul, <filename>
--		or false
		or Output_File_Name
	local commandPipe=CommandPipe(output_method
	)
	local _=commandPipe['echo hello']
		'echo world'
		--	auto insert new line after each command
		'ping 192.0.0.0 -n 1 -w 2000 >nul'
		--	wait sometime
		'echo time is %time%'
	commandPipe'echo goodbye'
	
	print'wait finish'
	output_content=commandPipe()--get output
	if output_content then
		assert(string.find(output_content,[[hello
world
time is %d+:%d+:%d+.%d+
goodbye]]))
	end
	
	print'close'
	output_content=commandPipe(false)
	assert(''==output_content or not output_method)--close, nothing remain to return
	local result={pcall(commandPipe,'anything')}
	assert(result[1]==false and string.find(result[2],'command pipe already closed'))
	
	print'restart'
	output_content=commandPipe()
	assert(''==output_content or not output_method)
	commandPipe'echo restart'
	
	
	output_content=commandPipe()
	if output_content then
		assert(output_content=='restart\n')--continue esult left
	end
	
	output_content=commandPipe(false)
	assert(''==output_content or not output_method)
	print'test done. result is OK'
	os.remove(Output_File_Name)
else;print'skip'
end;print''

if print'Test time cost:'
	or true
	then
	local count=50--loop to test time spend
	print('when repeat '..count..' times.')
	local startTime
	local expect_output_content do
		local output_contents={}
		for each=1,count do
			table.insert(output_contents,each)
		end
		table.insert(output_contents,'')
		expect_output_content=table.concat(output_contents,'\n')
	end
	local function time_cost(startTime)
		return string.format('%.3f',gettime()-startTime)
	end
	
	--------basic popen cost	--------
	startTime=gettime()
	for index=1,count do
		io.popen'':close()
	end
	print('Basic open-close cost: ',time_cost(startTime))
	
	--------traditional method--------
	io.open(Output_File_Name,'w'):close()
	startTime=gettime()
	for index=1,count do
		io.popen('>>'..Output_File_Name..' echo('..index):close()
	end
	
	output_content=get_output()
	assert(output_content==expect_output_content,'unexpect result')
	print('Traditional method: ',time_cost(startTime))
	os.remove(Output_File_Name)--erase
	
	--------use command pipe	--------
	io.open(Output_File_Name,'w'):close()
	startTime=gettime()
	local commandPipe=CommandPipe(false)
	for index=1,count do
		commandPipe('>>'..Output_File_Name..' echo('..index)
	end
	print('Command pipe method: ',time_cost(startTime))
	startTime=gettime()
	assert(nil==commandPipe())--此处使用'Output_File_Name'记录
	output_content=output_content or get_output()
	print('wait command pipe finish: ',time_cost(startTime))
	assert(output_content==expect_output_content,'unexpect result')
	assert(nil==commandPipe(false))--close
	
	os.remove(Output_File_Name)
	print'test done. result is OK'
else;print'skip'
end;print''

print'All finish'