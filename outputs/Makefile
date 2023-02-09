.PHONY: all replay

# For those who need `make "DOCKER=sudo docker"`
DOCKER=docker

# name of the container we'll generate the tutorial outputs with
container = ghcr.io/spack/tutorial:latest
raw_output = raw/*/*.out
subdirs = basics environments packaging stacks dev scripting
run_targets = $(addprefix run-,$(subdirs))

all:
	echo "Filtering raw outputs though col"
	for raw in $(raw_output); do \
		out=$$(echo $$raw | sed 's.raw/..'); \
		cat $$raw | perl -pe 's/\x1b\[\d+F\x1b\[J//g' | perl -pe 's/\033\[([01];)?\d+m//g' | col -bp > $$out; \
	done

$(addprefix run-local-,$(subdirs)):
	$(CURDIR)/$(@:run-local-%=%).sh

run: $(run_targets)

$(run_targets):
	$(DOCKER) run --rm -it \
		--mount type=bind,source=$(CURDIR),target=/project \
		${container} \
		/project/$(@:run-%=%).sh

interactive:
	$(DOCKER) run --rm -it \
		--mount type=bind,source=$(CURDIR),target=/project \
		${container}
