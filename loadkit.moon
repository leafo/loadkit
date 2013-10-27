
import insert, remove from table

dirsep, pathsep, wildcard = unpack [ c for c in package.config\gmatch "[^\n]" ]
loaders = -> package.loaders or package.searchers

escape_pattern = do
  punct = "[%^$()%.%[%]*+%-?%%]"
  (str) -> (str\gsub punct, (p) -> "%"..p)

wildcard = escape_pattern wildcard
modsep = escape_pattern "." -- module name hierarchy separator

insert_loader = (ext, handler, pos=2) ->
  search_paths = for path in package.path\gmatch "[^#{pathsep}]+"
    if p = path\match "^(.-)%.lua$"
      p .. "." .. ext
    else
      continue

  loader_fn = (name) ->
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

      if loaded[1] == nil
        return unpack loaded

      -> unpack loaded
    else
      "Could not load #{ext} file"

  insert loaders!, pos, loader_fn
  loader_fn

registered_handlers = {}

register = (ext, handler) ->
  real_ext = ext\match "^[^:]*"
  loader_fn = insert_loader real_ext, handler
  registered_handlers[ext] = loader_fn
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

{ :register, :unregister, _registered_handlers: registered_handlers }
