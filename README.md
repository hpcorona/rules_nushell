# rules_nushell

Tools to allow running nushell files using [Nushell](https://www.nushell.sh/).

## Why?

There is no easy way to write simple "shell script" files with multi-platform support in Bazel.

This is an attempt to provide something easy to use to solve this problem.

## Why nushell?

Because of several reasons:
* MIT license.
* Good multi-platform support.
* Easy way to handle arguments with type support.
* Small downloads.
* Single binary with good features and no hard-dependencies.
* Syntax seems easy.
* Looks like it has a good community.

## Usage?

Yes please.

```
# MODULE.bazel

bazel_dep(
  name = "rules_nushell",
  version = "",
)

git_override(
  module_name = "rules_nushell",
  remote = "",
)
```

```
# BUILD.bazel

load("@rules_nushell//nu:def.bzl", "nu_binary", "nu_module")

nu_module(
  name = "module",
  srcs = [
    "module.nu",
  ],
)

nu_binary(
  name = "test",
  entry_point = "test.nu",
  deps = [
    ":module",
  ],
)
```

Then run it:

```
bazelisk run //:test -- some parameters
```

That's it.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

## License

Apache 2.0; see [`LICENSE`](LICENSE) for details.

## Disclaimer

This project is not an official Google project. It is not supported by
Google and Google specifically disclaims all warranties as to its quality,
merchantability, or fitness for a particular purpose.

