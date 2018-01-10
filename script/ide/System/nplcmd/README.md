
### NPL command line interface

nplc is a simple implementation of npl cli, it also includes a simple interactive npl console to help you test some npl code.

nplc script is another core feature, now you can use npl or lua code to implement some command line tools with it.

for example:

```lua
-- Important: return a function to handle the cmd
return function(ctx)
    print("hello world!")
end

return _M
```

with nplc script, you can simply run "nplc your_script param1 param2 ... paramN" in the console, and nplc will load the script immidiately and execute the "run" function with {param1, param2, ..., paramN}

It's recommend to put the command line tool script into /usr/local/bin/, same as nplc. And add "#!/usr/bin/env nplc" to the first line, in this way, you can run the command anywhere with the command name.

for example:

filename: hello
```lua
#!/usr/bin/env nplc

-- Important: return a function to handle the cmd
return function(ctx)
    print("hello world!")
end

```

move file "hello" to /usr/local/bin/, then input "hello" in the console :)

### USEAGE

1. nplc console

```bash
nplc
```

2. nplc script

```bash
nplc your_script params
```

3. script in bin folder
```bash
script_name params
```
