const std = @import("std");
const TestContext = @import("../../src-self-hosted/test.zig").TestContext;
// self-hosted does not yet support PE executable files / COFF object files
// or mach-o files. So we do these test cases cross compiling for x86_64-linux.
const linux_x64 = std.zig.CrossTarget{
    .cpu_arch = .x86_64,
    .os_tag = .linux,
};

const linux_riscv64 = std.zig.CrossTarget{
    .cpu_arch = .riscv64,
    .os_tag = .linux,
};

const wasi = std.zig.CrossTarget{
    .cpu_arch = .wasm32,
    .os_tag = .wasi,
};

pub fn addCases(ctx: *TestContext) !void {
    {
        var case = ctx.exe("hello world with updates", linux_x64);

        case.addError("", &[_][]const u8{":1:1: error: no entry point found"});

        case.addError(
            \\export fn _start() noreturn {
            \\}
        , &[_][]const u8{":2:1: error: expected noreturn, found void"});

        // Regular old hello world
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    print();
            \\
            \\    exit();
            \\}
            \\
            \\fn print() void {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (1),
            \\          [arg1] "{rdi}" (1),
            \\          [arg2] "{rsi}" (@ptrToInt("Hello, World!\n")),
            \\          [arg3] "{rdx}" (14)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    return;
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (231),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "Hello, World!\n",
        );
        // Now change the message only
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    print();
            \\
            \\    exit();
            \\}
            \\
            \\fn print() void {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (1),
            \\          [arg1] "{rdi}" (1),
            \\          [arg2] "{rsi}" (@ptrToInt("What is up? This is a longer message that will force the data to be relocated in virtual address space.\n")),
            \\          [arg3] "{rdx}" (104)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    return;
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (231),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "What is up? This is a longer message that will force the data to be relocated in virtual address space.\n",
        );
        // Now we print it twice.
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    print();
            \\    print();
            \\
            \\    exit();
            \\}
            \\
            \\fn print() void {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (1),
            \\          [arg1] "{rdi}" (1),
            \\          [arg2] "{rsi}" (@ptrToInt("What is up? This is a longer message that will force the data to be relocated in virtual address space.\n")),
            \\          [arg3] "{rdx}" (104)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    return;
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (231),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            \\What is up? This is a longer message that will force the data to be relocated in virtual address space.
            \\What is up? This is a longer message that will force the data to be relocated in virtual address space.
            \\
        );
    }

    {
        var case = ctx.exe("hello world", linux_riscv64);
        // Regular old hello world
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    print();
            \\
            \\    exit();
            \\}
            \\
            \\fn print() void {
            \\    asm volatile ("ecall"
            \\        :
            \\        : [number] "{a7}" (64),
            \\          [arg1] "{a0}" (1),
            \\          [arg2] "{a1}" (@ptrToInt("Hello, World!\n")),
            \\          [arg3] "{a2}" ("Hello, World!\n".len)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    return;
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("ecall"
            \\        :
            \\        : [number] "{a7}" (94),
            \\          [arg1] "{a0}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "Hello, World!\n",
        );
    }

    {
        var case = ctx.exe("adding numbers at comptime", linux_x64);
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (1),
            \\          [arg1] "{rdi}" (1),
            \\          [arg2] "{rsi}" (@ptrToInt("Hello, World!\n")),
            \\          [arg3] "{rdx}" (10 + 4)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (@as(usize, 230) + @as(usize, 1)),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "Hello, World!\n",
        );
    }

    {
        var case = ctx.exe("adding numbers at runtime", linux_x64);
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    add(3, 4);
            \\
            \\    exit();
            \\}
            \\
            \\fn add(a: u32, b: u32) void {
            \\    if (a + b != 7) unreachable;
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (231),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "",
        );
    }

    {
        var case = ctx.exe("substracting numbers at runtime", linux_x64);
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    sub(7, 4);
            \\
            \\    exit();
            \\}
            \\
            \\fn sub(a: u32, b: u32) void {
            \\    if (a - b != 3) unreachable;
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (231),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "",
        );
    }

    {
        var case = ctx.exe("assert function", linux_x64);
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    add(3, 4);
            \\
            \\    exit();
            \\}
            \\
            \\fn add(a: u32, b: u32) void {
            \\    assert(a + b == 7);
            \\}
            \\
            \\pub fn assert(ok: bool) void {
            \\    if (!ok) unreachable; // assertion failure
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (231),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "",
        );

        // Tests copying a register. For the `c = a + b`, it has to
        // preserve both a and b, because they are both used later.
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    add(3, 4);
            \\
            \\    exit();
            \\}
            \\
            \\fn add(a: u32, b: u32) void {
            \\    const c = a + b; // 7
            \\    const d = a + c; // 10
            \\    const e = d + b; // 14
            \\    assert(e == 14);
            \\}
            \\
            \\pub fn assert(ok: bool) void {
            \\    if (!ok) unreachable; // assertion failure
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (231),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "",
        );

        // More stress on the liveness detection.
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    add(3, 4);
            \\
            \\    exit();
            \\}
            \\
            \\fn add(a: u32, b: u32) void {
            \\    const c = a + b; // 7
            \\    const d = a + c; // 10
            \\    const e = d + b; // 14
            \\    const f = d + e; // 24
            \\    const g = e + f; // 38
            \\    const h = f + g; // 62
            \\    const i = g + h; // 100
            \\    assert(i == 100);
            \\}
            \\
            \\pub fn assert(ok: bool) void {
            \\    if (!ok) unreachable; // assertion failure
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (231),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "",
        );

        // Requires a second move. The register allocator should figure out to re-use rax.
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    add(3, 4);
            \\
            \\    exit();
            \\}
            \\
            \\fn add(a: u32, b: u32) void {
            \\    const c = a + b; // 7
            \\    const d = a + c; // 10
            \\    const e = d + b; // 14
            \\    const f = d + e; // 24
            \\    const g = e + f; // 38
            \\    const h = f + g; // 62
            \\    const i = g + h; // 100
            \\    const j = i + d; // 110
            \\    assert(j == 110);
            \\}
            \\
            \\pub fn assert(ok: bool) void {
            \\    if (!ok) unreachable; // assertion failure
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (231),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "",
        );

        // Now we test integer return values.
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    assert(add(3, 4) == 7);
            \\    assert(add(20, 10) == 30);
            \\
            \\    exit();
            \\}
            \\
            \\fn add(a: u32, b: u32) u32 {
            \\    return a + b;
            \\}
            \\
            \\pub fn assert(ok: bool) void {
            \\    if (!ok) unreachable; // assertion failure
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (231),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "",
        );

        // Local mutable variables.
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    assert(add(3, 4) == 7);
            \\    assert(add(20, 10) == 30);
            \\
            \\    exit();
            \\}
            \\
            \\fn add(a: u32, b: u32) u32 {
            \\    var x: u32 = undefined;
            \\    x = 0;
            \\    x += a;
            \\    x += b;
            \\    return x;
            \\}
            \\
            \\pub fn assert(ok: bool) void {
            \\    if (!ok) unreachable; // assertion failure
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (231),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "",
        );

        // Optionals
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    const a: u32 = 2;
            \\    const b: ?u32 = a;
            \\    const c = b.?;
            \\    if (c != 2) unreachable;
            \\
            \\    exit();
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (231),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "",
        );

        // While loops
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    var i: u32 = 0;
            \\    while (i < 4) : (i += 1) print();
            \\    assert(i == 4);
            \\
            \\    exit();
            \\}
            \\
            \\fn print() void {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (1),
            \\          [arg1] "{rdi}" (1),
            \\          [arg2] "{rsi}" (@ptrToInt("hello\n")),
            \\          [arg3] "{rdx}" (6)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    return;
            \\}
            \\
            \\pub fn assert(ok: bool) void {
            \\    if (!ok) unreachable; // assertion failure
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (231),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "hello\nhello\nhello\nhello\n",
        );

        // Labeled blocks (no conditional branch)
        case.addCompareOutput(
            \\export fn _start() noreturn {
            \\    assert(add(3, 4) == 20);
            \\
            \\    exit();
            \\}
            \\
            \\fn add(a: u32, b: u32) u32 {
            \\    const x: u32 = blk: {
            \\        const c = a + b; // 7
            \\        const d = a + c; // 10
            \\        const e = d + b; // 14
            \\        break :blk e;
            \\    };
            \\    const y = x + a; // 17
            \\    const z = y + a; // 20
            \\    return z;
            \\}
            \\
            \\pub fn assert(ok: bool) void {
            \\    if (!ok) unreachable; // assertion failure
            \\}
            \\
            \\fn exit() noreturn {
            \\    asm volatile ("syscall"
            \\        :
            \\        : [number] "{rax}" (231),
            \\          [arg1] "{rdi}" (0)
            \\        : "rcx", "r11", "memory"
            \\    );
            \\    unreachable;
            \\}
        ,
            "",
        );
    }

    {
        var case = ctx.exe("wasm function calls", wasi);

        case.addCompareOutput(
            \\export fn _start() u32 {
            \\    foo();
            \\    bar();
            \\    return 42;
            \\}
            \\fn foo() void {
            \\    bar();
            \\    bar();
            \\}
            \\fn bar() void {}
        ,
            "42\n",
        );

        case.addCompareOutput(
            \\export fn _start() i64 {
            \\    bar();
            \\    foo();
            \\    foo();
            \\    bar();
            \\    foo();
            \\    bar();
            \\    return 42;
            \\}
            \\fn foo() void {
            \\    bar();
            \\}
            \\fn bar() void {}
        ,
            "42\n",
        );

        case.addCompareOutput(
            \\export fn _start() f32 {
            \\    bar();
            \\    foo();
            \\    return 42.0;
            \\}
            \\fn foo() void {
            \\    bar();
            \\    bar();
            \\    bar();
            \\}
            \\fn bar() void {}
        ,
            // This is what you get when you take the bits of the IEE-754
            // representation of 42.0 and reinterpret them as an unsigned
            // integer. Guess that's a bug in wasmtime.
            "1109917696\n",
        );
    }
}
