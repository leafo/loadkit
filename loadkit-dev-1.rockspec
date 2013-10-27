package = "loadkit"
version = "dev-1"

source = {
  url = "git://github.com/leafo/loadkit.git"
}

description = {
  summary = "Loadkit allows you to load arbitrary files within the Lua package path",
  detailed = [[
		Loadkit lets you register new file extension handlers that can be opened
		with require, or you can just search for files of any extension using the
		current search path.
  ]],
  homepage = "https://github.com/leafo/loadkit",
  maintainer = "Leaf Corcoran <leafot@gmail.com>",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1",
}

build = {
  type = "builtin",
  modules = {
    ["loadkit"] = "loadkit.lua",
  },
}

