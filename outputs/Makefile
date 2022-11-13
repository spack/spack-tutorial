.PHONY: all replay

# name of the container we'll generate the tutorial outputs with
container = ghcr.io/spack/tutorial:latest
raw_output = raw/*/*.out
subdirs = basics environments packaging environments stacks dev scripting

section = scripting

all:
	echo "Filtering raw outputs though col"
	for raw in $(raw_output); do \
		out=$$(echo $$raw | sed 's.raw/..'); \
		cat $$raw | perl -pe 's/\x1b\[\d+F\x1b\[J//g' | perl -pe 's/\033\[([01];)?\d+m//g' | col -bp > $$out; \
	done
	echo "Removing spurious = and # characters"
	for dir in $(subdirs); do \
		sed -i~ 's/==>[^ ]/==> /;s/\#/ /' $$dir/*.out; \
	done

run-local:
	${PWD}/${section}.sh

run:
	docker run --rm -it \
		--mount type=bind,source=${PWD},target=/project \
		${container} \
		/project/${section}.sh

interactive:
	docker run --rm -it \
		--mount type=bind,source=${PWD},target=/project \
		${container}
