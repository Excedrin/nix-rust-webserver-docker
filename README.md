Trivial example of one way to use [nix2container](https://github.com/nlewo/nix2container) to build a Docker image.

```
nix run -v 'github:Excedrin/nix-rust-webserver-docker/placeholder#default.copyToDockerDaemon'

docker run --name rust-web-server --rm -d -p 8080:8080 rust-web-server:20240819-placeholder

curl http://127.0.0.1:8080/

docker kill rust-web-server
```
