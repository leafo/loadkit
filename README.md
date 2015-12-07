# loadkit

Loadkit allows you to load arbitrary files within the Lua package path.

## Install

```bash
$ luarocks install loadkit
```

## Example

[`etlua`](http://github.com/leafo/etlua) is a library that lets you create
embedded Lua templates. The result of the template is a function that when
called returns the compiled template. Normally you need to load the template
and compile the it manually. Let's make it so `require` is aware of `.elua`
files and returns the compiled template.


Here's an example directory structure:

```
|-- example.lua
`-- templates
    |-- hello.elua
    `-- my_template.elua
```

And then we can run:

```lua
-- example.lua
local etlua = require "etlua"
local loadkit = require "loadkit"

-- register a handler for .elua files
loadkit.register("elua", function(file)
	return assert(etlua.compile(file:read("*a")))
end)

template = require "templates.my_template"
print(template())
```

The functionality of `require` is unchanged, if the template's module name is
required again it would return the cached value, avoiding any additional
searching.

### What's the point?

A project like [MoonScript](http://moonscript.org) uses a technique like this
to let you load compiled MoonScript as you would load Lua making the
integration seamless.

Alternatively, if you've ever wanted to bundle different kinds of file assets
inside of a Lua module but were unsure about how to resolve the correct path to
open the file you can use this module:

```lua
local js_loader = loadkit.make_loader("js")

-- find the actual path of your resource
local fname = js_loader("mymodule.some_script")
```

## Reference

The module can be loaded by doing:

```lua
local loadkit = require "loadkit"
```

### Functions

#### `loadkit.register(ext, handler)`

Registers a new loader for the extension `ext`. The handler is a function that
is responsible for creating the module after a matching file has been found.

The handler takes three arguments: `file`, `module_name`, `file_path`.

The `file` is a freshly opened Lua file object ready for reading. Loadkit will
automatically close the file after executing the handler if you don't close it.

`module_name` is the name of the module that was passed to require. `file_path`
is the path of the file that was opened when searching through the search path.

The return value of the handler determines if the module is loaded. If `nil` is
returned no module is loaded. Any other value returned is used as the value of
the module.

#### `success = loadkit.unregister(ext)`

Removes a handler that has already been registered. Returns `true` if found
handler to remove.

#### `bool = loadkit.is_registered(ext)`

Returns `true` if a loader has already been registered for the extension `ext`.

#### `loader = loadkit.make_loader(ext, [handler, package_path])`

Makes a loader without manipulating Lua's module loaders. The return value is a
function that takes a module name and returns the path of the file that matches
that module name if it could be found.

Handler is an optional function that works the same as in `register` from
above. If a handler is specified then its return value is returned by the
loader.

`package_path` defaults to the Lua install's `package.path` variable.

# Changelog

**1.1.0 -- Sun Dec  6 17:50:53 PST 2015**

* `make_loader` can operate on a custom package path
* Support lua 5.2 and above (fix unpack reference)

## License

MIT, Copyright (C) 2014 by Leaf Corcoran


