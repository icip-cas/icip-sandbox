SHELL = /bin/bash
HOST ?= $(shell hostname -I | awk '{print $$1}')
PORT ?= 8080
TEST_NP ?= 4
WORKERS ?= 4
MAX_MEM ?= unlimited
run:
	uvicorn sandbox.server.server:app --reload --host $(HOST) --port $(PORT)

run-online:
	echo "SAVE_BAD_CASES: $${SAVE_BAD_CASES}"
	ulimit -Sv $(MAX_MEM) && \
	ulimit -a && \
	uvicorn sandbox.server.server:app --host $(HOST) --port $(PORT) --workers $(WORKERS)

run-distributed:
	echo "SAVE_BAD_CASES: $${SAVE_BAD_CASES}"
	bash deploy/write_address.sh $(HOST) $(PORT) & 
	ulimit -Sv $(MAX_MEM) && \
	ulimit -a && \
	uvicorn sandbox.server.server:app --host $(HOST) --port $(PORT) --workers $(WORKERS)

build-server-image:
	docker build . -f scripts/Dockerfile.server -t sandbox:server

test:
	pytest -m "not cuda and not datalake and not dp_eval and not lean" -n $(TEST_NP)

test-cuda:
	pytest -m cuda

test-minor:
	pytest -m minor

test-verilog:
	pytest -m verilog

test-verilog-pdb:
	pytest -m verilog --pdb --capture=no

test-online:
	ONLINE_TEST=1 pytest

test-case:
	pytest -s -vv -k $(CASE)

format:
	pycln --config pyproject.toml
	isort sandbox/*
	yapf -ir sandbox/*

format-client:
	mv scripts/client/pyproject.toml scripts/faas/pyproject.toml && yapf -ir scripts/client/* && mv scripts/faas/pyproject.toml scripts/client/pyproject.toml

# mypy --explicit-package-bases sandbox
check:
	pycln --config pyproject.toml --check
	yapf --diff --recursive sandbox/*
	make test
