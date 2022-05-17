## 概述

使用Lua的`io.popen(..,'w')`，搭配'cmd /k'解析传入的命令(command)。可以保持宿主(host)持续，避免反复`io.popen-close`。

使用重定向(redirect)与中间文件（或`stdout`），获取(流1)返回值。
执行命令是异步(asynchronous)的，写入命令后便返回Lua，但可以通过关闭句柄（随后再新建打开），等待命令处理完毕(wait until finish)，正确获取返回值。

效果明显。特别适用于：
- 无需等待返回结果，
- 高频使用`io.popen`（或可取代`os.execute`）的情况。

除此，相应的，

- 需要*等待*执行完毕时，使用`os.execute`；
- 同时需要*返回值*时，使用`io.popen(..,'r')`

## 函数

`commandPipe=CommandPipe(initial_outputStreamName)`

- `initial_outputStreamName`：初始输出流，可以在命令中覆盖掉。

  - `nil`: 相当于`stdout`；
  - `false`: 相当于`nul`；
  - `filename`。
  - `''`（empty string）：内部维护`os.tmpname()`。

- `commandPipe`函数

  - `commandPipe'command'`：执行命令。
    
    - **命令**间，*等待*（wait / hang / block）。前一命令执行完后才执行下一命令。
      使用CMD中的管道(pipe `|`)使并行执行(asynchronous parallel)。
    - ***函数*** *不*等待*命令*。函数继续执行，*不等待*命令执行完毕。
    
    返回自身，支持链式语法`commandPipe'command''command2'..`。
    
  - `commandPipe['command']`：执行命令，返回结果。
    相当于`commandPipe'command'`+（如下的）`outputContent=commandPipe()`。
  
  - `outputContent=commandPipe()`：等待返回（阻塞），如果指定了filename，返回自上次以来的结果。
    不使用此函数，也可以自行读取输出文件，但无法掌握时机。
    可配合协程(coroutine)，减小无用等待。
  
  - `outputContent=commandPipe(false)`：关闭。
  
    如果有输出文件，重置。
    意义不大，可以等自动回收(GC)。
    关闭后使用`commandPipe()`再打开。
    返回结果同`commandPipe()`。

## 测试

详见：[test.lua](./test.lua)。用例（展示部分）：

```lua
commandPipe=CommandPipe''	--'': use tmpfile to receive output internally
print(commandPipe['echo %OS%'])	--equal `os.getenv'OS'`
```

```lua
commandPipe'echo hello'
    'echo world'
    'ping 192.0.0.0 -n 1 -w 2000 >nul'
    'echo time is %time%'
commandPipe'echo goodbye'()	--(): wait execute finish
...
```

结果（展示部分）：

```bat
Test basic use:
wait finish
close
restart
test done. result is OK

Test time cost:
when repeat 50 times.
Basic open-close cost: 	1.243
Traditional method: 	1.258
Command pipe method: 	0.064
wait command pipe finish: 	0.077
test done. result is OK

All finish
```
