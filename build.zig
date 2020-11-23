const std = @import("std");
const Builder = @import("std").build.Builder;

// pub fn baseCfg(step: anytype) void {}

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    var exe = b.addExecutable("ioke", "src/main.zig");
    // baseCfg(&exe);
    exe.addPackagePath("@ioke/ioke_object", "src/lang/IokeObject.zig");
    exe.addPackagePath("@ioke/message", "src/lang/Message.zig");
    exe.addPackagePath("@ioke/runtime", "src/lang/Runtime.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // const test_chain_context = b.addTest(
    //     "./src/lang/parser/ChainContext.zig "
    // );
    // var test_step = b.step(
    //     "test",
    //     "Run all tests"
    // );
    // const test_cmd = test_chain_context.run();
    // test_chain_context.addPackagePath("@ioke/ioke_object", "src/lang/IokeObject.zig");
    // test_chain_context.addPackagePath("@ioke/message", "src/lang/Message.zig");
    // test_cmd.step.dependOn(&run_cmd.step);
    // test_cmd.step.dependOn(test_step);


}
