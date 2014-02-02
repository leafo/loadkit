
loadkit = require "loadkit"

describe "loadkit", ->
  local old_loaders, old_loaded

  before_each ->
    old_loaders = { k,v for k,v in pairs package.loaders or package.searchers}
    old_loaded = { k,v for k,v in pairs package.loaded }

    for k in pairs loadkit._registered_handlers
      loadkit._registered_handlers[k] = nil

  after_each ->
    if package.loaders
      package.loaders = old_loaders
    else
      package.searchers = old_loaders

    for k in pairs package.loaded
      package.loaded[k] = nil

    for k,v in pairs old_loaded
      package.loaded[k] = v

  describe "register", ->
    it "should register basic handler", ->
      assert loadkit.register "leafo", -> "cool"
      assert.same "cool", require "spec.tests.thing"

    it "should register a tagged extension", ->
      assert loadkit.register "leafo:hello", -> "cool"
      assert.same "cool", require "spec.tests.thing"

    it "should load file as string", ->
      assert loadkit.register "leafo", (file) ->
        file\read "*a"

      assert.same "Hello world!\n", require "spec.tests.thing"

    it "should close the file", ->
      local f
      assert loadkit.register "leafo", (file) ->
        f = file
        file\read "*a"

      require "spec.tests.thing"
      assert.same "closed file", io.type(f)

    it "should not close file twice", ->
      assert loadkit.register "leafo", (file) ->
        out = file\read "*a"
        file\close!
        out

      require "spec.tests.thing"

    it "should pass expected arguments", ->
      assert loadkit.register "leafo", (file, mod_name, file_path) ->
        assert.same "file", io.type(file)
        assert.same "spec.tests.thing", mod_name
        assert.same "./spec/tests/thing.leafo", file_path
        "okay"

      require "spec.tests.thing"

    it "should allow loader function to return nil", ->
      fn = spy.new ->

      assert loadkit.register "leafo", ->
        fn!
        nil

      assert.has_error ->
        require "spec.tests.thing"

      assert.has_error ->
        require "spec.tests.thing"

      assert.spy(fn).was_called 2

    it "should register multiple loaders", ->
      assert loadkit.register "leafo", -> "leafo"
      assert loadkit.register "cats", -> "cats"

      assert.same "cats", require "spec.tests.file"
      assert.same "leafo", require "spec.tests.thing"

    -- tests before_each/after_each is cleaning correctly
    it "should not find file when nothing is registered", ->
      assert.has_error ->
        require "spec.tests.thing"

  describe "unregister", ->
    it "should respond to unregistered loader", ->
      status, err = loadkit.unregister "hello_world"
      assert.same nil, status
      assert.same "can't find existing loader `hello_world`", err

    it "should unregister basic handler", ->
      assert loadkit.register "leafo", -> "cool"
      assert loadkit.unregister "leafo"

      assert.has_error ->
        require "spec.tests.thing"

    it "should unregister tagged extension", ->
      assert loadkit.register "leafo", -> "cool"
      assert loadkit.register "leafo:tagged", -> "cool2"

      assert.same "cool2", require "spec.tests.thing"
      package.loaded["spec.tests.thing"] = nil

      assert loadkit.unregister "leafo:tagged"
      assert.same "cool", require "spec.tests.thing"

  describe "is_registered", ->
    it "should return true for registered ext", ->
      assert loadkit.register "leafo", -> "cool"
      assert.truthy loadkit.is_registered "leafo"

    it "should return false for registered ext", ->
      assert.falsy loadkit.is_registered "leafo"

  describe "make_loader", ->
    it "should find file", ->
      loader = loadkit.make_loader "cats"
      assert.same {}, {loader "spec.tests.thing"}
      assert.same { "./spec/tests/file.cats" }, { loader "spec.tests.file" }

