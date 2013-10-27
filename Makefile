
test:
	busted

build::
	moonc loadkit.moon

local: build
	luarocks make --local loadkit-dev-1.rockspec
