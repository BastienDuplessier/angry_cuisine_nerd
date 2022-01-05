.PHONY: build clean clean-site server reload install-deps

build:
	dune build

clean:
	dune clean

clean-site:
	rm -rf _site

fmt:
	dune build @fmt --auto-promote

server: build
	./src/angry_generator.exe serve

reload: clean clean-site
	dune build
	./src/angry_generator.exe build

remove-deps:
	opam remove yocaml yocaml_unix yocaml_yaml yocaml_markdown
	opam remove yocaml_jingoo
	opam pin remove yocaml yocaml_unix yocaml_yaml yocaml_markdown
	opem pin remove yocaml_jingoo

install-deps:
	opam install . --deps-only
	opam install yocaml
	opam install yocaml_unix yocaml_yaml yocaml_markdown yocaml_jingoo
