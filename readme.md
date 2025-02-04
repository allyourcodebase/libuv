# libuv

This is [`libuv`][libuv], packaged for [Zig](https://ziglang.org/).

## Status

In theory, the full intersection of platforms supported by libuv and platforms supported by Zig are supported build targets, but the less common targets are not tested.

Building the unit test executable for linux (and possibly other platforms) does not currently work because the unit test files directly `#include` some of the libuv source files (while also linking to `libuv.a`), and that causes duplicate symbol errors unless the linker command is assembled in a specific order. The zig build system does not enforce a specific order.

## Usage

First, update your `build.zig.zon`:

```sh
# Initialize a zig project if you haven't already
zig init
# replace <refname> with the version you want to use, e.g. 1.50.0
zig fetch --save git+https://github.com/allyourcodebase/libuv.git#<refname>
```

You can then import `libuv` in your `build.zig` with:

```zig
const libuv_dep = b.dependency("libuv", .{
    .target = target,
    .optimize = optimize,
});
your_exe.linkLibrary(libuv_dep.artifact("uv"));
```

## Dependencies

`libuv` only depends on core operating system libraries (and libc).

## Zig Version Support Matrix

|  Refname  | libuv Version  | Zig `0.13` | Zig `0.14.0-dev` |
|-----------|----------------|------------|------------------|
|           | `1.50.0`       | ✅         | ✅              |

[libuv]: https://github.com/libuv
