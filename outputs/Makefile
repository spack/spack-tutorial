.PHONY: update-outputs run interactive clean

# Tools
DOCKER := docker
DOCKER_RUN_OPTS :=

# Path to the host Docker socket and its group id. The cache section talks to a
# real Docker daemon (see run-cache), so its container needs access to the
# socket. The socket is owned by a group we must join with --group-add; detect
# its gid portably across Linux (stat -c) and BSD/macOS (stat -f).
DOCKER_SOCK := /var/run/docker.sock
DOCKER_SOCK_GID := $(shell stat -c '%g' $(DOCKER_SOCK) 2>/dev/null || stat -f '%g' $(DOCKER_SOCK) 2>/dev/null)

# Use this for Podman
#DOCKER := podman
#DOCKER_RUN_OPTS := --userns=keep-id --security-opt label=disable

# Use this for Finch
#DOCKER := finch
#DOCKER_RUN_OPTS := --platform=amd64


# Name of the container we'll generate the tutorial outputs with
container := ghcr.io/spack/tutorial:latest@sha256:978cbf0a169644b3bc06f30a397770ee935b1836aa742f7996b4d74d7a4e4721

# Sections to build
sections := environments

# Allow users to override variables (e.g. DOCKER := sudo docker)
-include Make.user

run_targets := $(addprefix run-,$(sections))

# Entrypoint
update-outputs: run
	echo "Filtering raw outputs though col"
	for raw in raw/*/*.out; do \
		out=$$(echo $$raw | sed 's.raw/..'); \
		cat $$raw | \
			perl -pe 's/\x1b]0;.+?\x07//g' | \
			perl -pe 's/\x1b\[\d+F\x1b\[J//g' | \
			perl -pe 's/\033\[([01];)?\d+m//g' | \
			col -bp | \
			sed '/^==> Waiting for/d' > $$out; \
	done

run: run-scripting
run-scripting: run-cache scripting.sh
#run-cache is defined below; it needs an extra docker arguments
run-dev: run-packaging dev.sh
run-packaging: run-stacks packaging.sh
run-stacks: run-environments stacks.sh
run-environments: run-basics environments.sh
run-basics: basics.sh init_spack.sh defs.sh

local: local-scripting
local-scripting: local-cache scripting.sh
local-cache: local-dev cache.sh
local-dev: local-packaging dev.sh
local-packaging: local-stacks packaging.sh
local-stacks: local-environments stacks.sh
local-environments: local-basics environments.sh
local-basics: basics.sh init_spack.sh defs.sh

local-%: %.sh init_spack.sh defs.sh
	$(CURDIR)/$(@:local-%=%).sh

# Common container invocation used by all run-<section> targets.
#   $(1) = script basename (e.g. environments)
#   $(2) = extra docker run arguments for this section (may be empty)
define run_section
$(DOCKER) run $(DOCKER_RUN_OPTS) --rm -t $(2) \
	--mount type=bind,source=$(CURDIR),target=/project \
	${container} \
	/project/$(1).sh
endef

run-%: %.sh init_spack.sh defs.sh
	$(call run_section,$(@:run-%=%),) && touch $@

# The cache section pushes to an OCI registry with 'spack buildcache' and runs
# real 'docker' commands so the generated output is an honest integration test.
# The host Docker socket is mounted in so those commands reach a real daemon,
# and --add-host maps localhost:5000 (used by spack and by the sibling
# containers' published port) to the host gateway. cache.sh starts the
# registry container and cleans it up on exit, including leftovers from a
# previously interrupted run.
run-cache: run-dev cache.sh init_spack.sh defs.sh
	$(call run_section,cache,-v $(DOCKER_SOCK):$(DOCKER_SOCK) \
        --group-add $(DOCKER_SOCK_GID) --add-host localhost:host-gateway) && touch $@

interactive:
	$(DOCKER) run $(DOCKER_RUN_OPTS) --rm -it \
		--mount type=bind,source=$(CURDIR),target=/project \
		${container}

$(addprefix clean-,$(sections)):
	rm -f $(@:clean-%=run-%) $(wildcard raw/$(@:clean-%=%)/*.out)

clean:
	rm -f $(run_targets) $(wildcard raw/*/*.out)
