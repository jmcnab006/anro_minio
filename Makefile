SHELL := /bin/bash
.PHONY: binaries lint syntax molecule test

binaries:
	./build/build.sh

lint:
	ansible-lint .

syntax:
	ansible-playbook --syntax-check molecule/default/converge.yml

molecule:
	molecule test

test: lint molecule
