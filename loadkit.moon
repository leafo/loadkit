VERSION = "1.1.0"

import insert, remove from table
unpack = table.unpack or _G.unpack

dirsep, pathsep, wildcard = unpack [ c for c in package.config\gmatch "[^\n]" ]
loaders = -> package.loaders or package.searchers

escape_pattern = do
  punct = "[%^$()%.%[%]*+%-?%%]"
  (str) -> (str\gsub punct, (p) -> "%"..p)

wildcard = escape_pattern wildcard
modsep = escape_pattern "." -- module name hierarchy separator

make_loader = (ext, handler, load_path=package.path) ->
  handler or= (_, _, ...) -> ...

  search_paths = for path in load_path\gmatch "[^#{pathsep}]+"
    if p = path\match "^(.-)%.lua$"
      p .. "." .. ext
    else
      continue

  (name) ->
    name_path = name\gsub modsep, dirsep

    local file, file_path
    for search_path in *search_paths
      file_path = search_path\gsub wildcard, name_path
      file = io.open file_path
      break if file

    if file
      loaded = { handler file, name, file_path }

      -- close the file if it hasn't been closed
      unless io.type(file) == "closed file"
        file\close!

      unpack loaded

registered_handlers = {}

register = (ext, handler, pos=2) ->
  assert ext, "missing extension"
  assert handler, "missing handler"

  real_ext = ext\match "^[^:]*"

  loader_fn = make_loader real_ext, handler

  wrapped_loader = (name) ->
    res, err = loader_fn name

    if res != nil
      -> res
    else
      err or "could not load `#{real_ext}` file"

  insert loaders!, pos, wrapped_loader
  registered_handlers[ext] = wrapped_loader

  true

unregister = (ext) ->
  loader_fn = registered_handlers[ext]

  unless loader_fn
    return nil, "can't find existing loader `#{ext}`"

  for i, l in pairs loaders!
    if l == loader_fn
      remove loaders!, i
      return true

  nil, "loader `#{ext}` is no longer in searchers"

is_registered = (ext) ->
  not not registered_handlers[ext]

{
  :VERSION
  :register, :unregister, :is_registered, :make_loader
  _registered_handlers: registered_handlers
}
