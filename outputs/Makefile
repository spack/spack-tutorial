.PHONY: update-outputs run interactive clean

# Tools
DOCKER := docker
DOCKER_RUN_OPTS :=

# Use this for Podman
#DOCKER := podman
#DOCKER_RUN_OPTS := --userns=keep-id --security-opt label=disable

# Use this for Finch
#DOCKER := finch
#DOCKER_RUN_OPTS := --platform=amd64


# Name of the container we'll generate the tutorial outputs with
container := ghcr.io/spack/tutorial:latest@sha256:417900cce4592159456050a91d844fc9e81fcb01125a55555092fa450ce59a67

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
		cat $$raw | perl -pe 's/\x1b]0;.+?\x07//g' | perl -pe 's/\x1b\[\d+F\x1b\[J//g' | perl -pe 's/\033\[([01];)?\d+m//g' | col -bp | sed '/^==> Waiting for/d' > $$out; \
	done

run: run-scripting

run-scripting: run-cache scripting.sh
run-cache: run-dev cache.sh
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

run-%: %.sh init_spack.sh defs.sh
	$(DOCKER) run $(DOCKER_RUN_OPTS) --rm -t \
		--mount type=bind,source=$(CURDIR),target=/project \
		${container} \
		/project/$(@:run-%=%).sh && touch $@

interactive:
	$(DOCKER) run $(DOCKER_RUN_OPTS) --rm -it \
		--mount type=bind,source=$(CURDIR),target=/project \
		${container}

$(addprefix clean-,$(sections)):
	rm -f $(@:clean-%=run-%) $(wildcard raw/$(@:clean-%=%)/*.out)

clean:
	rm -f $(run_targets) $(wildcard raw/*/*.out)
