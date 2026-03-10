"""Platform provider and rules for OCI images."""

load(
    "@aspect_bazel_lib//lib:copy_to_directory.bzl",
    "copy_to_directory_bin_action",
)

OCIPlatformInfo = provider(
    fields = {
        "os": "The OS identifier in OCI format (e.g. 'linux', 'darwin', 'windows')",
        "cpu": "The CPU architecture in OCI format (e.g. 'amd64', 'arm64', '386')",
        "variant": "(Optional) The CPU variant in OCI format (e.g. 'v8', 'v7')",
    },
    doc = "Carries platform information for OCI images.",
)

def _oci_platform_impl(ctx):
    return [
        OCIPlatformInfo(
            os = ctx.attr.os,
            cpu = ctx.attr.cpu,
            variant = ctx.attr.variant or None,
        ),
    ]

oci_platform = rule(
    implementation = _oci_platform_impl,
    doc = "Creates a target that provides OCIPlatformInfo with the given os, cpu, and variant.",
    attrs = {
        "os": attr.string(
            mandatory = True,
            doc = "The OS in OCI format (e.g. 'linux', 'darwin', 'windows')",
        ),
        "cpu": attr.string(
            mandatory = True,
            doc = "The CPU architecture in OCI format (e.g. 'amd64', 'arm64', '386')",
        ),
        "variant": attr.string(
            mandatory = False,
            doc = "The CPU variant in OCI format (e.g. 'v8', 'v7')",
        ),
    },
)

def _oci_pulled_image_impl(ctx):
    toolchain = ctx.toolchains["@aspect_bazel_lib//lib:copy_to_directory_toolchain_type"]

    out = ctx.actions.declare_directory("layout")

    copy_to_directory_bin_action(
        ctx,
        name = ctx.label.name,
        dst = out,
        copy_to_directory_bin = toolchain.copy_to_directory_info.bin,
        files = ctx.files.srcs,
        hardlink = "on",
        include_external_repositories = ["*"],
    )

    return [
        DefaultInfo(
            files = depset([out]),
        ),
        OCIPlatformInfo(
            os = ctx.attr.os,
            cpu = ctx.attr.cpu,
            variant = ctx.attr.variant or None,
        ),
    ]

oci_pulled_image = rule(
    implementation = _oci_pulled_image_impl,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = True,
            doc = "The OCI layout files (blobs, oci-layout, index.json).",
        ),
        "os": attr.string(
            mandatory = True,
            doc = "The image operating system in OCI format.",
        ),
        "cpu": attr.string(
            mandatory = True,
            doc = "The CPU architecture in OCI format.",
        ),
        "variant": attr.string(
            mandatory = False,
            doc = "The CPU variant in OCI format.",
        ),
    },
    doc = "Rule to assemble an OCI layout directory and provide OCIPlatformInfo.",
    toolchains = ["@aspect_bazel_lib//lib:copy_to_directory_toolchain_type"],
)
