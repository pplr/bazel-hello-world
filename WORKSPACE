workspace(
    name = "hello-world",
    managed_directories = {
        "@npm": ["node_modules"],
        "@npm_backend": ["backend/node_modules"],
        "@npm_e2e-test": ["e2e-test/node_modules"],
    },
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "build_bazel_rules_nodejs",
    sha256 = "4952ef879704ab4ad6729a29007e7094aef213ea79e9f2e94cbe1c9a753e63ef",
    urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/2.2.0/rules_nodejs-2.2.0.tar.gz"],
)

load("@build_bazel_rules_nodejs//:index.bzl", "node_repositories", "yarn_install")

# install nodejs, npm, and yarn
node_repositories(package_json = ["//:package.json"])

yarn_install(
    name = "npm",
    package_json = "//:package.json",
    yarn_lock = "//:yarn.lock",
)

yarn_install(
    name = "npm_backend",
    package_json = "//backend:package.json",
    yarn_lock = "//backend:yarn.lock",
)

yarn_install(
    name = "npm_e2e-test",
    package_json = "//e2e-test:package.json",
    yarn_lock = "//e2e-test:yarn.lock",
)

# Docker

http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "4521794f0fba2e20f3bf15846ab5e01d5332e587e9ce81629c7f96c793bb7036",
    strip_prefix = "rules_docker-0.14.4",
    urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.14.4/rules_docker-v0.14.4.tar.gz"],
)

load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    container_repositories = "repositories",
)

container_repositories()

load("@io_bazel_rules_docker//repositories:deps.bzl", container_deps = "deps")

container_deps()

load("@io_bazel_rules_docker//repositories:pip_repositories.bzl", "pip_deps")

pip_deps()

load(
    "@io_bazel_rules_docker//container:container.bzl",
    "container_pull",
)

container_pull(
  name = "java_base",
  registry = "gcr.io",
  repository = "distroless/java",
  # 'tag' is also supported, but digest is encouraged for reproducibility.
  digest = "sha256:deadbeef",
)

# docker nodejs image

load(
    "@io_bazel_rules_docker//nodejs:image.bzl",
    _nodejs_image_repos = "repositories",
)

_nodejs_image_repos()