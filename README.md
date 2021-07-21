# Angry Cuisine Nerd

Recueil de recettes culinaires. J'en ferais peut être un blog pour faire plaisir à certains.
Non, je ne participerais pas à Top Chef, j'ai peur des caméras.
(english below)

## English

Just some cooking recipes. Nothing interesting.

### How to build this website

First, make sure you have OCaml ('>= 4.11') and Opam installed. Then after downloading the sources, go to the project directory and install the dependencies with the command `make install-deps`.

- Now you can run `make build` to build the generator. It will produce a binary `src/angry_generator.exe`.
- Running `./src/angry_generator.exe` will build the website into `_site/_`.
- You can use `make server` in order to launch the sad `python simple server` on the generated website.
- Your site will be alive on http://localhost:8000.
