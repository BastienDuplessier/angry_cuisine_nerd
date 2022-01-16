# Angry Cuisine Nerd

Recueil de recettes culinaires. J'en ferais peut être un blog pour faire plaisir à certains.
Non, je ne participerais pas à Top Chef, j'ai peur des caméras.
(english below)

## English

Just some cooking recipes. Nothing interesting.

### How to build this website

First, make sure you have OCaml ('>= 4.11') and Opam installed. Then after downloading the sources, go to the project directory and install the dependencies with the command `make install-deps`.

> If some updates to `preface` or `yocaml` are not taken into account, feel free to remove the dependencies (`opam remove preface yocaml yocaml_unix`) before re-running the command call.

- Now you can run `make build` to build the generator. It will produce a binary `src/angry_generator.exe`.
- Running `./src/angry_generator.exe build` will build the website into `_site/angry_cuisine_nerd`.
- You can use `make server` in order to launch the sad `YOCaml simple server` on the generated website.
- Your site will be alive on http://localhost:8000/angry_cuisine_nerd.
