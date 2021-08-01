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

install-deps:
	opam remove preface yocaml yocaml_unix yocaml_yaml yocaml_markdown
	opam pin remove preface yocaml yocaml_unix yocaml_yaml yocaml_markdown
	opam install . --deps-only
	opam install preface
	opam install yocaml
	opam install yocaml_unix yocaml_yaml yocaml_markdown
