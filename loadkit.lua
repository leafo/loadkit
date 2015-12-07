local VERSION = "1.1.0"
local insert, remove
do
  local _obj_0 = table
  insert, remove = _obj_0.insert, _obj_0.remove
end
local unpack = table.unpack or _G.unpack
local dirsep, pathsep, wildcard = unpack((function()
  local _accum_0 = { }
  local _len_0 = 1
  for c in package.config:gmatch("[^\n]") do
    _accum_0[_len_0] = c
    _len_0 = _len_0 + 1
  end
  return _accum_0
end)())
local loaders
loaders = function()
  return package.loaders or package.searchers
end
local escape_pattern
do
  local punct = "[%^$()%.%[%]*+%-?%%]"
  escape_pattern = function(str)
    return (str:gsub(punct, function(p)
      return "%" .. p
    end))
  end
end
wildcard = escape_pattern(wildcard)
local modsep = escape_pattern(".")
local make_loader
make_loader = function(ext, handler, load_path)
  if load_path == nil then
    load_path = package.path
  end
  handler = handler or function(_, _, ...)
    return ...
  end
  local search_paths
  do
    local _accum_0 = { }
    local _len_0 = 1
    for path in load_path:gmatch("[^" .. tostring(pathsep) .. "]+") do
      local _continue_0 = false
      repeat
        do
          local p = path:match("^(.-)%.lua$")
          if p then
            _accum_0[_len_0] = p .. "." .. ext
          else
            _continue_0 = true
            break
          end
        end
        _len_0 = _len_0 + 1
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    search_paths = _accum_0
  end
  return function(name)
    local name_path = name:gsub(modsep, dirsep)
    local file, file_path
    for _index_0 = 1, #search_paths do
      local search_path = search_paths[_index_0]
      file_path = search_path:gsub(wildcard, name_path)
      file = io.open(file_path)
      if file then
        break
      end
    end
    if file then
      local loaded = {
        handler(file, name, file_path)
      }
      if not (io.type(file) == "closed file") then
        file:close()
      end
      return unpack(loaded)
    end
  end
end
local registered_handlers = { }
local register
register = function(ext, handler, pos)
  if pos == nil then
    pos = 2
  end
  assert(ext, "missing extension")
  assert(handler, "missing handler")
  local real_ext = ext:match("^[^:]*")
  local loader_fn = make_loader(real_ext, handler)
  local wrapped_loader
  wrapped_loader = function(name)
    local res, err = loader_fn(name)
    if res ~= nil then
      return function()
        return res
      end
    else
      return err or "could not load `" .. tostring(real_ext) .. "` file"
    end
  end
  insert(loaders(), pos, wrapped_loader)
  registered_handlers[ext] = wrapped_loader
  return true
end
local unregister
unregister = function(ext)
  local loader_fn = registered_handlers[ext]
  if not (loader_fn) then
    return nil, "can't find existing loader `" .. tostring(ext) .. "`"
  end
  for i, l in pairs(loaders()) do
    if l == loader_fn then
      remove(loaders(), i)
      return true
    end
  end
  return nil, "loader `" .. tostring(ext) .. "` is no longer in searchers"
end
local is_registered
is_registered = function(ext)
  return not not registered_handlers[ext]
end
return {
  VERSION = VERSION,
  register = register,
  unregister = unregister,
  is_registered = is_registered,
  make_loader = make_loader,
  _registered_handlers = registered_handlers
}
