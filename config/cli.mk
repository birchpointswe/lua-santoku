CLI_NAME = $(NAME)-cli

CLI_ROCKSPEC = $(BUILD_DIR)/$(CLI_NAME)-$(VERSION).rockspec
CLI_ROCKSPEC_T = config/cli.rockspec

CLI_SRC = src/santoku-cli.lua
CLI_DEST = $(INST_BINDIR)/toku

TOKU_TPL = LUA_PATH="src/?.lua;$(LUA_PATH)" $(LUA) $(CLI_SRC) template

cli-install: $(CLI_ROCKSPEC)
	luarocks make $(CLI_ROCKSPEC)

luarocks-cli-install: $(CLI_DEST)

cli-upload: $(CLI_ROCKSPEC)
	@if test -z "$(LUAROCKS_API_KEY)"; then echo "Missing LUAROCKS_API_KEY variable"; exit 1; fi
	@if ! git diff --quiet; then echo "Commit your changes first"; exit 1; fi
	git tag "$(VERSION)"
	git push --tags 
	luarocks upload --api-key "$(LUAROCKS_API_KEY)" "$(CLI_ROCKSPEC)"

$(CLI_DEST): $(CLI_SRC)
	test -n "$(INST_LUADIR)"
	test -n "$(INST_BINDIR)"
	mkdir -p "$(dir $(CLI_DEST))"
	cp "$(CLI_SRC)" "$(CLI_DEST)"

$(CLI_ROCKSPEC): $(CLI_ROCKSPEC_T)
	NAME="$(CLI_NAME)" VERSION="$(VERSION)" \
	HOMEPAGE="$(HOMEPAGE)" LICENSE="$(LICENSE)" \
	GIT_URL="$(GIT_URL)" \
		$(TOKU_TPL) -f "$^" -o "$@"

.PHONY: cli-install luarocks-cli-install cli-upload
