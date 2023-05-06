LIB_NAME = $(NAME)

LIB_ROCKSPEC = $(BUILD_DIR)/$(LIB_NAME)-$(LIB_VERSION).rockspec
LIB_ROCKSPEC_T = config/lib.rockspec

LIB_SRC = $(shell find src/$(LIB_NAME) -name '*.lua')
LIB_DIST = $(patsubst src/%, $(INST_LUADIR)/%, $(LIB_SRC))

LIB_ROCKSPEC = $(BUILD_DIR)/$(LIB_NAME)-$(VERSION).rockspec
LIB_ROCKSPEC_T = config/lib.rockspec

test: $(LIB_ROCKSPEC) 
	luarocks test $(LIB_ROCKSPEC) $(ARGS)

iterate: $(LIB_ROCKSPEC) 
	luarocks test $(LIB_ROCKSPEC) iterate $(ARGS)

lib-install: $(LIB_ROCKSPEC)
	luarocks make $(LIB_ROCKSPEC) $(ARGS) 

luarocks-lib-install: $(LIB_DIST)

lib-upload: $(LIB_ROCKSPEC)
	cd "$(BUILD_DIR)" && \
		luarocks upload --api-key "$(LUAROCKS_API_KEY)" "../$(LIB_ROCKSPEC)" $(ARGS)

$(INST_LUADIR)/$(LIB_NAME)/%: src/$(LIB_NAME)/% 
	test -n "$(INST_LUADIR)"
	mkdir -p "$(dir $@)"
	cp "$^" "$@"

$(LIB_ROCKSPEC): $(LIB_ROCKSPEC_T)
	NAME="$(LIB_NAME)" VERSION="$(VERSION)" \
	HOMEPAGE="$(HOMEPAGE)" LICENSE="$(LICENSE)" \
	GIT_URL="$(GIT_URL)" \
		$(TOKU) template -f "$^" -o "$@"

.PHONY: test lib-install luarocks-lib-install lib-upload
