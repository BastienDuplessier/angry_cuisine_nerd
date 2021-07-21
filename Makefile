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
	opam pin add yocaml git+ssh://git@github.com/xhtmlboi/yocaml.git
	opam pin add yocaml_unix git+ssh://git@github.com/xhtmlboi/yocaml.git
	opam install . --deps-only
