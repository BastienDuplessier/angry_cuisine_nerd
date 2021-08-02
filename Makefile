.PHONY: build clean clean-site server reload install-deps

build:
	dune build

clean:
	dune clean

clean-site:
	rm -rf _site

server:
	python3 -m http.server --directory _site/

reload: clean clean-site
	dune build
	./src/angry_generator.exe

remove-deps:
	opam remove preface yocaml yocaml_unix yocaml_yaml yocaml_markdown
	opam remove yocaml_jingoo
	opam pin remove preface yocaml yocaml_unix yocaml_yaml yocaml_markdown
	opem pin remove yocaml_jingoo

install-deps:
	opam install . --deps-only
	opam install preface
	opam install yocaml
	opam install yocaml_unix yocaml_yaml yocaml_markdown yocaml_jingoo
