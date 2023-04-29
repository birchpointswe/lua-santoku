NAME = santoku
VERSION = 0.0.17-1
GIT_URL = git@github.com:broma0/lua-santoku.git
HOMEPAGE = https://github.com/broma0/lua-santoku
LICENSE = MIT

BUILD_DIR = build

LUA = $(shell luarocks config lua_interpreter)

all:

include config/cli.mk
include config/lib.mk

clean:
	rm -rf "$(BUILD_DIR)"

.PHONY: all clean
