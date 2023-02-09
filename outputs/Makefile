.PHONY: run update-outputs interactive clean

# For those who need `make "DOCKER=sudo docker"`
DOCKER=docker

# name of the container we'll generate the tutorial outputs with
container = ghcr.io/spack/tutorial:latest
raw_output = raw/*/*.out
subdirs = basics environments packaging stacks dev scripting
run_targets = $(addprefix run-,$(subdirs))

# Entrypoint
run: $(run_targets)

update-outputs:
	echo "Filtering raw outputs though col"
	for raw in $(raw_output); do \
		out=$$(echo $$raw | sed 's.raw/..'); \
		cat $$raw | perl -pe 's/\x1b\[\d+F\x1b\[J//g' | perl -pe 's/\033\[([01];)?\d+m//g' | col -bp > $$out; \
	done

$(addprefix local-run-,$(subdirs)):
	$(CURDIR)/$(@:local-run-%=%).sh

$(run_targets): run-%: %.sh init_spack.sh defs.sh

$(run_targets):
	$(DOCKER) run --rm -t \
		--mount type=bind,source=$(CURDIR),target=/project \
		${container} \
		/project/$(@:run-%=%).sh && touch $@

interactive:
	$(DOCKER) run --rm -it \
		--mount type=bind,source=$(CURDIR),target=/project \
		${container}

clean:
	rm -f $(run_targets)
