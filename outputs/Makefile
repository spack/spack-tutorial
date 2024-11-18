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
container := ghcr.io/spack/tutorial:latest

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

local: local-scripting
local-scripting: local-dev scripting.sh
#local-cache: local-dev cache.sh
local-dev: local-packaging dev.sh
local-packaging: local-stacks packaging.sh
local-stacks: local-environments stacks.sh
# local-config: local-environments config.sh # coming soon^TM
local-environments: local-basics environments.sh
local-basics: basics.sh init_spack.sh defs.sh

local-%: %.sh init_spack.sh defs.sh
	$(CURDIR)/$(@:local-%=%).sh

run:
	$(DOCKER) run $(DOCKER_RUN_OPTS) --rm -t \
		--mount type=bind,source=$(CURDIR),target=/project -w /project \
		${container} "make local"

interactive:
	$(DOCKER) run $(DOCKER_RUN_OPTS) --rm -it \
		--mount type=bind,source=$(CURDIR),target=/project -w /project \
		${container}

$(addprefix clean-,$(sections)):
	rm -f $(@:clean-%=run-%) $(wildcard raw/$(@:clean-%=%)/*.out)

clean:
	rm -f $(run_targets) $(wildcard raw/*/*.out)
