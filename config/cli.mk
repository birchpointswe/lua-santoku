CLI_NAME ?= $(NAME)-cli

CLI_ROCKSPEC ?= $(BUILD_DIR)/$(CLI_NAME)-$(VERSION).rockspec
CLI_ROCKSPEC_T ?= config/cli.rockspec

CLI_SRC ?= src/santoku-cli.lua
CLI_DEST ?= $(INST_BINDIR)/toku

TOKU ?= LUA_PATH="src/?.lua;$(LUA_PATH)" $(LUA) $(CLI_SRC)

cli-install: $(CLI_ROCKSPEC)
	luarocks make $(CLI_ROCKSPEC) $(ARGS)

luarocks-cli-install: $(CLI_DEST)

cli-upload: $(CLI_ROCKSPEC)
	cd "$(BUILD_DIR)" && \
		luarocks upload --skip-pack --api-key "$(LUAROCKS_API_KEY)" "../$(CLI_ROCKSPEC)" $(ARGS)

$(CLI_DEST): $(CLI_SRC)
	@if test -z "$(INST_BINDIR)"; then echo "Missing INST_BINDIR variable"; exit 1; fi
	mkdir -p "$(dir $(CLI_DEST))"
	cp "$(CLI_SRC)" "$(CLI_DEST)"

$(CLI_ROCKSPEC): $(CLI_ROCKSPEC_T)
	NAME="$(CLI_NAME)" VERSION="$(VERSION)" \
	HOMEPAGE="$(HOMEPAGE)" LICENSE="$(LICENSE)" \
	GIT_URL="$(GIT_URL)" \
		$(TOKU) template -f "$^" -o "$@"

.PHONY: cli-install luarocks-cli-install cli-upload
