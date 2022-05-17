## 概述

使用Lua的`io.popen(..,'w')`，搭配'cmd /k'解析传入的命令(command)。可以保持宿主(host)持续，避免反复`io.popen-close`。

使用重定向(redirect)与中间文件（或`stdout`），获取(流1)返回值。
执行命令是异步(asynchronous)的，写入命令后便返回Lua，但可以通过关闭句柄（随后再新建打开），等待命令处理完毕(wait until finish)，正确获取返回值。

## 函数

`commandPipe=CommandPipe(initial_outputStreamName)`

- `initial_outputStreamName`：初始输出流，可以在命令中覆盖掉。

  - `nil`: 相当于`stdout`
  - `false`: 相当于`nul`
  - `filename`

- `commandPipe`函数

  - `commandPipe'command'`、`commandPipe['command']`：执行命令，异步。
    返回自身，支持链式语法`commandPipe'command''command2'..`。

  - `outputContent=commandPipe()`：等待返回（阻塞），如果指定了filename，返回自上次以来的结果。

  - `outputContent=commandPipe(false)`：关闭。

    如果有输出文件，重置。
    意义不大，可以等自动回收(GC)。
    关闭后使用`commandPipe()`再打开。
    返回结果同`commandPipe()`。

## 测试

test.lua:

```lua
commandPipe['echo hello']
    'echo world'
    'ping 192.0.0.0 -n 1 -w 2000 >nul'
    'echo time is %time%'
commandPipe'echo goodbye'
...
```

可尝试设置(customer)`output_method`、`count`。

结果

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

基础概念来自前一个尝试[LuaCommandBatchLoop](https://github.com/robertlzj/LuaCommandBatchLoop)。