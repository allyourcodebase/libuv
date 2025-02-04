pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const build_tests = b.option(
        bool,
        "build-tests",
        "Build the unit test executable (default: false)",
    ) orelse false;
    const build_benchmarks = b.option(
        bool,
        "build-benchmarks",
        "Build the benchmarks executable (default: false)",
    ) orelse false;

    const upstream = b.dependency("libuv", .{});

    const lib = b.addStaticLibrary(.{
        .name = "uv",
        .target = target,
        .optimize = optimize,
    });

    const cflags: []const []const u8 = &.{
        "-fvisibility=hidden",
        "-fno-strict-aliasing",
        "-std=gnu90",
    };

    const src_root = upstream.path("src");
    const include_root = upstream.path("include");
    const test_root = upstream.path("test");

    lib.linkLibC();
    lib.addCSourceFiles(.{
        .root = src_root,
        .files = common_sources,
        .flags = cflags,
    });
    lib.addIncludePath(src_root);
    lib.addIncludePath(include_root);

    const tinfo = target.result;
    switch (tinfo.os.tag) {
        .windows => {
            lib.root_module.addCMacro("_WIN32_WINNT", "0x0A00");
            lib.root_module.addCMacro("WIN32_LEAN_AND_MEAN", "");
            lib.root_module.addCMacro("_CRT_DECLARE_NONSTDC_NAMES", "0");

            lib.linkSystemLibrary("psapi");
            lib.linkSystemLibrary("user32");
            lib.linkSystemLibrary("advapi32");
            lib.linkSystemLibrary("iphlpapi");
            lib.linkSystemLibrary("userenv");
            lib.linkSystemLibrary("ws2_32");
            lib.linkSystemLibrary("dbghelp");
            lib.linkSystemLibrary("ole32");
            lib.linkSystemLibrary("shell32");
            lib.addCSourceFiles(.{
                .root = src_root,
                .files = win_sources,
                .flags = cflags,
            });
            lib.installHeader(
                include_root.path(b, "uv/win.h"),
                "uv/win.h",
            );
            lib.installHeader(
                include_root.path(b, "uv/tree.h"),
                "uv/tree.h",
            );
        },
        else => {
            lib.root_module.addCMacro("_FILE_OFFSET_BITS", "64");
            lib.root_module.addCMacro("_LARGEFILE_SOURCE", "");
            lib.addCSourceFiles(.{
                .root = src_root,
                .files = unix_sources,
                .flags = cflags,
            });
            lib.installHeader(
                include_root.path(b, "uv/unix.h"),
                "uv/unix.h",
            );
            if (!tinfo.isAndroid())
                lib.linkSystemLibrary("pthread");

            if (tinfo.isDarwin()) {
                lib.root_module.addCMacro("_DARWIN_UNLIMITED_SELECT", "1");
                lib.root_module.addCMacro("_DARWIN_USE_64_BIT_INODE", "1");
                lib.addCSourceFiles(.{
                    .root = src_root,
                    .files = darwin_sources,
                    .flags = cflags,
                });
                lib.installHeader(
                    include_root.path(b, "uv/darwin.h"),
                    "uv/darwin.h",
                );
            } else if (tinfo.isAndroid()) {
                lib.root_module.addCMacro("_GNU_SOURCE", "");
                lib.linkSystemLibrary("dl");
                lib.addCSourceFiles(.{
                    .root = src_root,
                    .files = android_sources,
                    .flags = cflags,
                });
                lib.installHeader(
                    include_root.path(b, "uv/linux.h"),
                    "uv/linux.h",
                );
            } else switch (tinfo.os.tag) {
                .linux => {
                    lib.root_module.addCMacro("_GNU_SOURCE", "");
                    lib.root_module.addCMacro("_POSIX_C_SOURCE", "200112");
                    lib.linkSystemLibrary("dl");
                    lib.linkSystemLibrary("rt");
                    lib.addCSourceFiles(.{
                        .root = src_root,
                        .files = linux_sources,
                        .flags = cflags,
                    });
                    lib.installHeader(
                        include_root.path(b, "uv/linux.h"),
                        "uv/linux.h",
                    );
                },
                .aix => {
                    lib.root_module.addCMacro("_ALL_SOURCE", "");
                    lib.root_module.addCMacro("_LINUX_SOURCE_COMPAT", "");
                    lib.root_module.addCMacro("_THREAD_SAFE", "");
                    lib.root_module.addCMacro("_XOPEN_SOURCE", "500");
                    lib.root_module.addCMacro("HAVE_SYS_AHAFS_EVPRODS_H", "");
                    lib.linkSystemLibrary("perfstat");
                    lib.addCSourceFiles(.{
                        .root = src_root,
                        .files = aix_sources,
                        .flags = cflags,
                    });
                    lib.installHeader(
                        include_root.path(b, "uv/aix.h"),
                        "uv/aix.h",
                    );
                },
                .haiku => {
                    lib.root_module.addCMacro("_BSD_SOURCE", "");
                    lib.linkSystemLibrary("bsd");
                    lib.linkSystemLibrary("network");
                    lib.addCSourceFiles(.{
                        .root = src_root,
                        .files = haiku_sources,
                        .flags = cflags,
                    });
                    lib.installHeader(
                        include_root.path(b, "uv/posix.h"),
                        "uv/posix.h",
                    );
                },
                .hurd => {
                    lib.root_module.addCMacro("_GNU_SOURCE", "");
                    lib.root_module.addCMacro("_POSIX_C_SOURCE", "200112");
                    lib.root_module.addCMacro("_XOPEN_SOURCE", "500");
                    lib.linkSystemLibrary("dl");
                    lib.addCSourceFiles(.{
                        .root = src_root,
                        .files = hurd_sources,
                        .flags = cflags,
                    });
                    lib.installHeader(
                        include_root.path(b, "uv/posix.h"),
                        "uv/posix.h",
                    );
                },
                .dragonfly => {
                    lib.addCSourceFiles(.{
                        .root = src_root,
                        .files = dragonfly_sources,
                        .flags = cflags,
                    });
                    lib.installHeader(
                        include_root.path(b, "uv/bsd.h"),
                        "uv/bsd.h",
                    );
                },
                .freebsd => {
                    lib.addCSourceFiles(.{
                        .root = src_root,
                        .files = freebsd_sources,
                        .flags = cflags,
                    });
                    lib.installHeader(
                        include_root.path(b, "uv/bsd.h"),
                        "uv/bsd.h",
                    );
                },
                .netbsd => {
                    lib.linkSystemLibrary("kvm");
                    lib.addCSourceFiles(.{
                        .root = src_root,
                        .files = netbsd_sources,
                        .flags = cflags,
                    });
                    lib.installHeader(
                        include_root.path(b, "uv/bsd.h"),
                        "uv/bsd.h",
                    );
                },
                .openbsd => {
                    lib.addCSourceFiles(.{
                        .root = src_root,
                        .files = openbsd_sources,
                        .flags = cflags,
                    });
                    lib.installHeader(
                        include_root.path(b, "uv/bsd.h"),
                        "uv/bsd.h",
                    );
                },
                .illumos, .solaris => {
                    lib.root_module.addCMacro("__EXTENSIONS__", "");
                    lib.root_module.addCMacro("_XOPEN_SOURCE", "500");
                    lib.root_module.addCMacro("_REENTRANT", "");
                    lib.linkSystemLibrary("kstat");
                    lib.linkSystemLibrary("nsl");
                    lib.linkSystemLibrary("sendfile");
                    lib.linkSystemLibrary("socket");
                    lib.addCSourceFiles(.{
                        .root = src_root,
                        .files = solaris_sources,
                        .flags = cflags,
                    });
                    lib.installHeader(
                        include_root.path(b, "uv/sunos.h"),
                        "uv/sunos.h",
                    );
                },
                else => @panic("Unsupported build target"),
            }
        },
    }

    for (install_headers) |header| {
        lib.installHeader(
            include_root.path(b, header),
            header,
        );
    }

    b.installArtifact(lib);

    if (build_tests) {
        const tests = b.addExecutable(.{
            .name = "uv_run_tests_a",
            .target = target,
            .optimize = optimize,
        });
        tests.addCSourceFiles(.{
            .root = test_root,
            .files = test_sources,
            .flags = cflags,
        });
        if (tinfo.os.tag == .windows) {
            tests.addCSourceFiles(.{
                .root = test_root,
                .files = win_test_sources,
                .flags = cflags,
            });
            tests.addCSourceFile(.{
                .file = src_root.path(b, "win/snprintf.c"),
                .flags = cflags,
            });
        } else {
            tests.addCSourceFiles(.{
                .root = test_root,
                .files = unix_test_sources,
                .flags = cflags,
            });
        }
        tests.addIncludePath(src_root);
        tests.addIncludePath(include_root);
        tests.linkLibrary(lib);
        b.installArtifact(tests);
    }

    if (build_benchmarks) {
        const benchmarks = b.addExecutable(.{
            .name = "uv_run_benchmarks_a",
            .target = target,
            .optimize = optimize,
        });

        benchmarks.addCSourceFiles(.{
            .root = test_root,
            .files = benchmark_sources,
            .flags = cflags,
        });
        if (tinfo.os.tag == .windows) {
            benchmarks.addCSourceFiles(.{
                .root = test_root,
                .files = win_test_sources,
                .flags = cflags,
            });
            benchmarks.addCSourceFile(.{
                .file = src_root.path(b, "win/snprintf.c"),
                .flags = cflags,
            });
        } else {
            benchmarks.addCSourceFiles(.{
                .root = test_root,
                .files = unix_test_sources,
                .flags = cflags,
            });
        }
        benchmarks.addIncludePath(src_root);
        benchmarks.addIncludePath(include_root);
        benchmarks.linkLibrary(lib);
        b.installArtifact(benchmarks);
    }
}

const install_headers: []const []const u8 = &.{
    "uv.h",
    "uv/errno.h",
    "uv/threadpool.h",
    "uv/version.h",
};

const common_sources: []const []const u8 = &.{
    "fs-poll.c",
    "idna.c",
    "inet.c",
    "random.c",
    "strscpy.c",
    "strtok.c",
    "thread-common.c",
    "threadpool.c",
    "timer.c",
    "uv-common.c",
    "uv-data-getter-setters.c",
    "version.c",
};

const unix_sources: []const []const u8 = &.{
    "unix/async.c",
    "unix/core.c",
    "unix/dl.c",
    "unix/fs.c",
    "unix/getaddrinfo.c",
    "unix/getnameinfo.c",
    "unix/loop-watcher.c",
    "unix/loop.c",
    "unix/pipe.c",
    "unix/poll.c",
    "unix/process.c",
    "unix/random-devurandom.c",
    "unix/signal.c",
    "unix/stream.c",
    "unix/tcp.c",
    "unix/thread.c",
    "unix/tty.c",
    "unix/udp.c",
};

const aix_sources: []const []const u8 = &.{
    "unix/aix.c",
    "unix/aix-common.c",
};

const android_sources: []const []const u8 = &.{
    "unix/linux.c",
    "unix/procfs-exepath.c",
    "unix/random-getentropy.c",
    "unix/random-getrandom.c",
    "unix/random-sysctl-linux.c",

    "unix/proctitle.c",
};

const linux_sources: []const []const u8 = &.{
    "unix/linux.c",
    "unix/procfs-exepath.c",
    "unix/random-getrandom.c",
    "unix/random-sysctl-linux.c",

    "unix/proctitle.c",
};

const darwin_sources: []const []const u8 = &.{
    "unix/darwin-proctitle.c",
    "unix/darwin.c",
    "unix/fsevents.c",
    "unix/random-getentropy.c",

    "unix/proctitle.c",
    "unix/bsd-ifaddrs.c",
    "unix/kqueue.c",
};

const dragonfly_sources: []const []const u8 = &.{
    "unix/freebsd.c",
    "unix/posix-hrtime.c",
    "unix/bsd-proctitle.c",
    "unix/bsd-ifaddrs.c",
    "unix/kqueue.c",
};

const freebsd_sources: []const []const u8 = &.{
    "unix/freebsd.c",
    "unix/posix-hrtime.c",
    "unix/bsd-proctitle.c",
    "unix/random-getrandom.c",
};
const netbsd_sources: []const []const u8 = &.{
    "unix/posix-hrtime.c",
    "unix/bsd-proctitle.c",
    "unix/netbsd.c",
};
const openbsd_sources: []const []const u8 = &.{
    "unix/posix-hrtime.c",
    "unix/bsd-proctitle.c",
    "unix/random-getentropy.c",
    "unix/openbsd.c",
};

const solaris_sources: []const []const u8 = &.{
    "unix/no-proctitle.c",
    "unix/sunos.c",
};

const haiku_sources: []const []const u8 = &.{
    "unix/haiku.c",
    "unix/bsd-ifaddrs.c",
    "unix/no-fsevents.c",
    "unix/no-proctitle.c",
    "unix/posix-hrtime.c",
    "unix/posix-poll.c",
};

const hurd_sources: []const []const u8 = &.{
    "unix/bsd-ifaddrs.c",
    "unix/no-fsevents.c",
    "unix/no-proctitle.c",
    "unix/posix-hrtime.c",
    "unix/posix-poll.c",
    "unix/hurd.c",
};

const cygwin_sources: []const []const u8 = &.{
    "unix/cygwin.c",
    "unix/bsd-ifaddrs.c",
    "unix/no-fsevents.c",
    "unix/no-proctitle.c",
    "unix/posix-hrtime.c",
    "unix/posix-poll.c",
    "unix/procfs-exepath.c",
    "unix/sysinfo-loadavg.c",
    "unix/sysinfo-memory.c",
};

const win_sources: []const []const u8 = &.{
    "win/async.c",
    "win/core.c",
    "win/detect-wakeup.c",
    "win/dl.c",
    "win/error.c",
    "win/fs.c",
    "win/fs-event.c",
    "win/getaddrinfo.c",
    "win/getnameinfo.c",
    "win/handle.c",
    "win/loop-watcher.c",
    "win/pipe.c",
    "win/thread.c",
    "win/poll.c",
    "win/process.c",
    "win/process-stdio.c",
    "win/signal.c",
    "win/snprintf.c",
    "win/stream.c",
    "win/tcp.c",
    "win/tty.c",
    "win/udp.c",
    "win/util.c",
    "win/winapi.c",
    "win/winsock.c",
};

const win_gnu_sources: []const []const u8 = &.{
    "unix/cygwin.c",
    "unix/bsd-ifaddrs.c",
    "unix/no-fsevents.c",
    "unix/no-proctitle.c",
    "unix/posix-hrtime.c",
    "unix/posix-poll.c",
    "unix/procfs-exepath.c",
    "unix/sysinfo-loadavg.c",
    "unix/sysinfo-memory.c",
};

const benchmark_sources: []const []const u8 = &.{
    "benchmark-async-pummel.c",
    "benchmark-async.c",
    "benchmark-fs-stat.c",
    "benchmark-getaddrinfo.c",
    "benchmark-loop-count.c",
    "benchmark-queue-work.c",
    "benchmark-million-async.c",
    "benchmark-million-timers.c",
    "benchmark-multi-accept.c",
    "benchmark-ping-pongs.c",
    "benchmark-ping-udp.c",
    "benchmark-pound.c",
    "benchmark-pump.c",
    "benchmark-sizes.c",
    "benchmark-spawn.c",
    "benchmark-tcp-write-batch.c",
    "benchmark-thread.c",
    "benchmark-udp-pummel.c",
    "blackhole-server.c",
    "echo-server.c",
    "run-benchmarks.c",
    "runner.c",
};

const win_test_sources: []const []const u8 = &.{
    "runner-win.c",
};

const unix_test_sources: []const []const u8 = &.{
    "runner-unix.c",
};

const test_sources: []const []const u8 = &.{
    "blackhole-server.c",
    "echo-server.c",
    "run-tests.c",
    "runner.c",
    "test-active.c",
    "test-async-null-cb.c",
    "test-async.c",
    "test-barrier.c",
    "test-callback-stack.c",
    "test-close-fd.c",
    "test-close-order.c",
    "test-condvar.c",
    "test-connect-unspecified.c",
    "test-connection-fail.c",
    "test-cwd-and-chdir.c",
    "test-default-loop-close.c",
    "test-delayed-accept.c",
    "test-dlerror.c",
    "test-eintr-handling.c",
    "test-embed.c",
    "test-emfile.c",
    "test-env-vars.c",
    "test-error.c",
    "test-fail-always.c",
    "test-fork.c",
    "test-fs-copyfile.c",
    "test-fs-event.c",
    "test-fs-poll.c",
    "test-fs.c",
    "test-fs-readdir.c",
    "test-fs-fd-hash.c",
    "test-fs-open-flags.c",
    "test-get-currentexe.c",
    "test-get-loadavg.c",
    "test-get-memory.c",
    "test-get-passwd.c",
    "test-getaddrinfo.c",
    "test-gethostname.c",
    "test-getnameinfo.c",
    "test-getsockname.c",
    "test-getters-setters.c",
    "test-gettimeofday.c",
    "test-handle-fileno.c",
    "test-homedir.c",
    "test-hrtime.c",
    "test-idle.c",
    "test-idna.c",
    "test-iouring-pollhup.c",
    "test-ip4-addr.c",
    "test-ip6-addr.c",
    "test-ip-name.c",
    "test-ipc-heavy-traffic-deadlock-bug.c",
    "test-ipc-send-recv.c",
    "test-ipc.c",
    "test-loop-alive.c",
    "test-loop-close.c",
    "test-loop-configure.c",
    "test-loop-handles.c",
    "test-loop-stop.c",
    "test-loop-time.c",
    "test-metrics.c",
    "test-multiple-listen.c",
    "test-mutexes.c",
    "test-not-readable-nor-writable-on-read-error.c",
    "test-not-writable-after-shutdown.c",
    "test-osx-select.c",
    "test-pass-always.c",
    "test-ping-pong.c",
    "test-pipe-bind-error.c",
    "test-pipe-close-stdout-read-stdin.c",
    "test-pipe-connect-error.c",
    "test-pipe-connect-multiple.c",
    "test-pipe-connect-prepare.c",
    "test-pipe-getsockname.c",
    "test-pipe-pending-instances.c",
    "test-pipe-sendmsg.c",
    "test-pipe-server-close.c",
    "test-pipe-set-fchmod.c",
    "test-pipe-set-non-blocking.c",
    "test-platform-output.c",
    "test-poll-close-doesnt-corrupt-stack.c",
    "test-poll-close.c",
    "test-poll-closesocket.c",
    "test-poll-multiple-handles.c",
    "test-poll-oob.c",
    "test-poll.c",
    "test-process-priority.c",
    "test-process-title-threadsafe.c",
    "test-process-title.c",
    "test-queue-foreach-delete.c",
    "test-random.c",
    "test-readable-on-eof.c",
    "test-ref.c",
    "test-run-nowait.c",
    "test-run-once.c",
    "test-semaphore.c",
    "test-shutdown-close.c",
    "test-shutdown-eof.c",
    "test-shutdown-simultaneous.c",
    "test-shutdown-twice.c",
    "test-signal-multiple-loops.c",
    "test-signal-pending-on-close.c",
    "test-signal.c",
    "test-socket-buffer-size.c",
    "test-spawn.c",
    "test-stdio-over-pipes.c",
    "test-strscpy.c",
    "test-strtok.c",
    "test-tcp-alloc-cb-fail.c",
    "test-tcp-bind-error.c",
    "test-tcp-bind6-error.c",
    "test-tcp-close-accept.c",
    "test-tcp-close-after-read-timeout.c",
    "test-tcp-close-while-connecting.c",
    "test-tcp-close.c",
    "test-tcp-close-reset.c",
    "test-tcp-connect-error-after-write.c",
    "test-tcp-connect-error.c",
    "test-tcp-connect-timeout.c",
    "test-tcp-connect6-error.c",
    "test-tcp-create-socket-early.c",
    "test-tcp-flags.c",
    "test-tcp-oob.c",
    "test-tcp-open.c",
    "test-tcp-read-stop.c",
    "test-tcp-reuseport.c",
    "test-tcp-read-stop-start.c",
    "test-tcp-rst.c",
    "test-tcp-shutdown-after-write.c",
    "test-tcp-try-write.c",
    "test-tcp-write-in-a-row.c",
    "test-tcp-try-write-error.c",
    "test-tcp-unexpected-read.c",
    "test-tcp-write-after-connect.c",
    "test-tcp-write-fail.c",
    "test-tcp-write-queue-order.c",
    "test-tcp-write-to-half-open-connection.c",
    "test-tcp-writealot.c",
    "test-test-macros.c",
    "test-thread-affinity.c",
    "test-thread-equal.c",
    "test-thread.c",
    "test-thread-name.c",
    "test-thread-priority.c",
    "test-threadpool-cancel.c",
    "test-threadpool.c",
    "test-timer-again.c",
    "test-timer-from-check.c",
    "test-timer.c",
    "test-tmpdir.c",
    "test-tty-duplicate-key.c",
    "test-tty-escape-sequence-processing.c",
    "test-tty.c",
    "test-udp-alloc-cb-fail.c",
    "test-udp-bind.c",
    "test-udp-connect.c",
    "test-udp-connect6.c",
    "test-udp-create-socket-early.c",
    "test-udp-dgram-too-big.c",
    "test-udp-ipv6.c",
    "test-udp-mmsg.c",
    "test-udp-multicast-interface.c",
    "test-udp-multicast-interface6.c",
    "test-udp-multicast-join.c",
    "test-udp-multicast-join6.c",
    "test-udp-multicast-ttl.c",
    "test-udp-open.c",
    "test-udp-options.c",
    "test-udp-send-and-recv.c",
    "test-udp-send-hang-loop.c",
    "test-udp-send-immediate.c",
    "test-udp-sendmmsg-error.c",
    "test-udp-send-unreachable.c",
    "test-udp-try-send.c",
    "test-udp-recv-in-a-row.c",
    "test-udp-reuseport.c",
    "test-uname.c",
    "test-walk-handles.c",
    "test-watcher-cross-stop.c",
};

const std = @import("std");
