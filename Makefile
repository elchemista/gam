LAKE ?= $(if $(wildcard lean/.toolchain/bin/lake),./.toolchain/bin/lake,lake)

.PHONY: build check
build:
	cd lean && $(LAKE) build

check: build
	python3 conformance/run.py
