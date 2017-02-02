# Meta Programming in NPL
Meta programming allows you to extend NPL syntax using the NPL language itself. For example, following code are valid in NPL. 
```
local a=1;
loop(){  please execute the code 10 times with i
    echo(a+i)
    async(){
        echo("This is from worker thread");
    }
}
```
Here loop, async are extended NPL syntax defined elsewhere.

The concept is first developed by [LISP programming language](http://lisp-lang.org/) in 1960s. However, despite the power of LISP, its syntax is hard to read for most programmers nowadays. NPL introduces a similar concept called `Function-Expression`, which can be mixed very well with the original NPL syntax.

The syntax of NPL's Function-Expression is `name(input, ...){ ...  }`

Files with `*.npl` extension support Function-Expression syntax by default. For example
```
NPL.load("(gl)script/tests/helloworld.npl")
NPL.loadstring("-- source code here", "filename_here")
```

## Function-Expression User Guide

### `def` expression

    def(<name>, <params>){
        --mode:<mode>
        statements
    }

+ \<name\>:name of new structure to be defined, name could not be null
+ \<params\>:parameters to be passed to defined structure
          multiple parameters should be seperated by comma
          unknown number parameters, using ...
+ \<mode\>:mode is set at the first line of comment inside block. Mode
           could be strict, line and token. When different mode is set,
           different parsing strategy is used in defined function expression.
           If nothing specified, strict mode is used.
+ \<statements\>: statements here are template code, which would be applied
                  to final code without any change. However, one exception is
                  +{} structure. Code inside +{} would be executed during compiling.
                  And some default functions are provided to give users more control.

**Default functions in +{}**     
_emit(str, l)_: emit str at the line l. when no str is specified, it emit whole code chunk
inside function expression block. when no l is specifiec, it emit at first line    
_emitline(fl, ll)_: used only in line mode. emit code chunk from line fl to ll. If no ll specified
it emit from fl to end of code chunk    
_params(p)_: emit parameter p    


**Usage**   
After defining a function expression, it could be used like this:   

    <name>(<params>){
         statements in specified mode
    }

**Mode**
* strict: statements in strict mode are followed the rules of original npl/lua grammar    
* line: statements in line mode are treated as lines, no grammar and syntax rules   
* token: statements in token mode are treated as token lists, original symbols and keywords 
are kept, but no grammar and syntax rules    

## Examples 
### Example 1

    def("translate", x, y, z){
        push()
        translate(+{params(x)}, +{params(y)}, +{params(z)})
        +{emit()}
        pop()
    }
    
    translate(1,2,3){
        rotate(45)
    }

The above chunk will compiled into

    push()
    translate(1,2,3)
    rotate(45)
    pop()

### Example 2

    def("loop"){
	  --mode:line
	  +{local line = ast:getLines(1,1)
	    local times, i = line:match("execute the code (%w+) times with (%l)")
	    if not times then times="1" end
	    if not i then i="i" end
           }
     for +{emit(i)}=1, +{emit(times)} do
     +{emitline(2)}
     end
     }

     loop(){execute the code 10 times with j
        print(2+j)
        print(3)
        print(4)
     }

The above chunk will compiled into

    do for j=1, 10 do
    print(2+j)
    print(3)
    print(4) end end

For more examples, please see our test [here](https://github.com/NPLPackages/main/tree/master/script/ide/System/Compiler/tests)
or [dsl definition file here](https://github.com/NPLPackages/main/tree/master/script/ide/System/Compiler/dsl)
