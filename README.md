Trivial example of one way to use [nix2container](https://github.com/nlewo/nix2container) to build a Docker image.

```
nix run -v 'github:Excedrin/nix-rust-webserver-docker/main#default.copyToDockerDaemon'

docker run --name rust-web-server --rm -d -p 8080:8080 rust-web-server:20240819-21f2753

curl http://127.0.0.1:8080/

docker kill rust-web-server
```

This build is deterministic, so that particular revision will have exactly this hash:
```
docker inspect db3db050fa9abe134041d05127c2b68a7c255543040f15461be7662d0d275b11
```
Update: that revision doesn't build that hash, probably because something else got updated (I didn't have nix2container pinned to a revision in the flake). Also this all depends on the platform being the same, so Nix on Mac doesn't build the same container hash. I updated the instructions to just build main instead.
