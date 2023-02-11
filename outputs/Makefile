.PHONY: update-outputs run interactive clean

# For those who need `make "DOCKER=sudo docker"`
DOCKER=docker

# name of the container we'll generate the tutorial outputs with
container = ghcr.io/spack/tutorial:latest
raw_output = raw/*/*.out
subdirs = basics cache dev environments modules packaging scripting stacks
run_targets = $(addprefix run-,$(subdirs))

# Entrypoint
update-outputs: run
	echo "Filtering raw outputs though col"
	for raw in $(raw_output); do \
		out=$$(echo $$raw | sed 's.raw/..'); \
		cat $$raw | perl -pe 's/\x1b\[\d+F\x1b\[J//g' | perl -pe 's/\033\[([01];)?\d+m//g' | col -bp | sed '/^==> Waiting for/d' > $$out; \
	done

run: $(run_targets)

$(addprefix local-run-,$(subdirs)):
	$(CURDIR)/$(@:local-run-%=%).sh

$(run_targets): run-%: %.sh init_spack.sh defs.sh
	$(DOCKER) run --rm -t \
		--mount type=bind,source=$(CURDIR),target=/project \
		${container} \
		/project/$(@:run-%=%).sh && touch $@

interactive:
	$(DOCKER) run --rm -it \
		--mount type=bind,source=$(CURDIR),target=/project \
		${container}

$(addprefix clean-,$(subdirs)):
	rm -f $(@:clean-%=run-%) $(wildcard raw/$(@:clean-%=%)/*.out)

clean:
	rm -f $(run_targets) $(wildcard raw/*/*.out)
