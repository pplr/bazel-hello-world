"""Test rule that fails if a source file has too long lines."""

load("@bazel_skylib//lib:dicts.bzl", "dicts")

load(
    "@io_bazel_rules_docker//container:layer_tools.bzl",
    _get_layers = "get_from_target",
    _incr_load = "incremental_load",
    _layer_tools = "tools",
)

load(
    "@io_bazel_rules_docker//skylib:label.bzl",
    _string_to_label = "string_to_label",
)


_TEMPLATE = "//tools:load-images.sh.tpl"

def _docker_compose(import_command, docker_compose):
    """Return shell commands for running images import and docker-compose"""

    return """
set -eu
{import_command}
docker-compose -f {docker_compose} up --exit-code-from test --renew-anon-volumes
""".format(import_command = import_command, docker_compose = docker_compose)

def _impl(ctx):

    # toolchain_info = ctx.toolchains["@io_bazel_rules_docker//toolchains/docker:toolchain_type"].info

    # Compute the set of layers from the image_targets.
    image_target_dict = _string_to_label(
        ctx.attr.image_targets,
        ctx.attr.image_target_strings,
    )

    images = {}
    runfiles = [ctx.file.compose_file]
    for unresolved_tag in ctx.attr.images:
        tag = ctx.expand_make_variables("images", unresolved_tag, {})

        target = ctx.attr.images[unresolved_tag]

        layer = _get_layers(ctx, ctx.label.name, image_target_dict[target])
        images[tag] = layer
        runfiles.append(layer.get("config"))
        runfiles.append(layer.get("config_digest"))
        runfiles += layer.get("unzipped_layer", [])
        runfiles += layer.get("diff_id", [])
        if layer.get("legacy"):
            runfiles.append(layer.get("legacy"))

    docker_import = ctx.actions.declare_file("docker_import")
    runfiles.append(docker_import)

    _incr_load(
        ctx,
        images,
        docker_import,
        stamp = False,
    )

    ctx.actions.write(
        content = _docker_compose(docker_import.short_path, ctx.file.compose_file.short_path),
        output = ctx.outputs.executable,
        is_executable = True,
    )

    # ctx.actions.expand_template(
    #     template = ctx.file._template,
    #     substitutions = {
    #         "%{docker_tool_path}": toolchain_info.tool_path,
    #         "%{docker_image}": ctx.file.image.short_path,
    #         "%{compose_file}": ctx.file.compose_file.short_path,
    #     },
    #     output = ctx.outputs.executable,
    #     is_executable = True,
    # )

    # To ensure the files needed by the script are available, we put them in
    # the runfiles.
    return [DefaultInfo(
        runfiles = ctx.runfiles(files = runfiles),
        executable = ctx.outputs.executable,
        )]

docker_compose_internal_test = rule(
    implementation = _impl,
    attrs = dicts.add({
        "image_target_strings": attr.string_list(),
        # Implicit dependencies.
        "image_targets": attr.label_list(allow_files = True),
        "images": attr.string_dict(),
        "compose_file": attr.label(allow_single_file = True),
        "_template": attr.label(
            default = Label(_TEMPLATE),
            allow_single_file = True,
        ),
    }, _layer_tools),
    test = True,
    toolchains=["@io_bazel_rules_docker//toolchains/docker:toolchain_type"],
)


# Example:
#   docker_compose_test(
#     name = "foo",
#     images = {
#       "ubuntu:latest": ":blah",
#       "foo.io/bar:canary": "//baz:asdf",
#     },
#     compose_file = "docker-compose.yml"
#   )
def docker_compose_test(**kwargs):
    """Package several container images into a single tarball.

    Args:
        **kwargs: See above.
    """
    for reserved in ["image_targets", "image_target_strings"]:
        if reserved in kwargs:
            fail("reserved for internal use by docker_compose_test macro", attr = reserved)

    if "images" in kwargs:
        values = {value: None for value in kwargs["images"].values()}.keys()
        kwargs["image_targets"] = values
        kwargs["image_target_strings"] = values

    docker_compose_internal_test(**kwargs)