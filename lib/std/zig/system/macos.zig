// SPDX-License-Identifier: MIT
// Copyright (c) 2015-2020 Zig Contributors
// This file is part of [zig](https://ziglang.org/), which is MIT licensed.
// The MIT license requires this copyright notice to be included in all copies
// and substantial portions of the software.
const std = @import("std");
const assert = std.debug.assert;
const mem = std.mem;

pub fn version_from_build(build: []const u8) !std.builtin.Version {
    // build format:
    //   19E287 (example)
    //   xxyzzz
    //
    // major = 10
    // minor = x - 4 = 19 - 4 = 15
    // patch = ascii(y) - 'A' = 'E' - 'A' = 69 - 65 = 4
    // answer: 10.15.4
    //
    // note: patch is typical but with some older releases (before 10.8) zzz is considered

    // never return anything below 10.0.0
    var result = std.builtin.Version{ .major = 10, .minor = 0, .patch = 0 };

    // parse format-x
    var yindex: usize = 0;
    {
        while (yindex < build.len) : (yindex += 1) {
            if (build[yindex] < '0' or build[yindex] > '9') break;
        }
        if (yindex == 0) return result;
        const x = std.fmt.parseUnsigned(u16, build[0..yindex], 10) catch return error.InvalidVersion;
        if (x < 4) return result;
        result.minor = x - 4;
    }

    // parse format-y, format-z
    {
        // expect two more
        if (build.len < yindex + 2) return error.InvalidVersion;
        const y = build[yindex];
        if (y < 'A') return error.InvalidVersion;
        var zend = yindex + 1;
        while (zend < build.len) {
            if (build[zend] < '0' or build[zend] > '9') break;
            zend += 1;
        }
        if (zend == yindex + 1) return error.InvalidVersion;
        const z = std.fmt.parseUnsigned(u16, build[yindex + 1 .. zend], 10) catch return error.InvalidVersion;

        result.patch = switch (result.minor) {
            // TODO: compiler complains without explicit @as() coercion
            0 => @as(u32, switch (y) { // Cheetah: 10.0
                'K' => 0,
                'L' => 1,
                'P' => @as(u32, block: {
                    if (z < 13) break :block 2;
                    break :block 3;
                }),
                'Q' => 4,
                else => return error.InvalidVersion,
            }),
            1 => @as(u32, switch (y) { // Puma: 10.1
                'G' => 0,
                'M' => 1,
                'P' => 2,
                'Q' => @as(u32, block: {
                    if (z < 125) break :block 3;
                    break :block 4;
                }),
                'S' => 5,
                else => return error.InvalidVersion,
            }),
            2 => @as(u32, switch (y) { // Jaguar: 10.2
                'C' => 0,
                'D' => 1,
                'F' => 2,
                'G' => 3,
                'I' => 4,
                'L' => @as(u32, block: {
                    if (z < 60) break :block 5;
                    break :block 6;
                }),
                'R' => @as(u32, block: {
                    if (z < 73) break :block 7;
                    break :block 8;
                }),
                'S' => 8,
                else => return error.InvalidVersion,
            }),
            3 => @as(u32, switch (y) { // Panther: 10.3
                'B' => 0,
                'C' => 1,
                'D' => 2,
                'F' => 3,
                'H' => 4,
                'M' => 5,
                'R' => 6,
                'S' => 7,
                'U' => 8,
                'W' => 9,
                else => return error.InvalidVersion,
            }),
            4 => @as(u32, switch (y) { // Tiger: 10.4
                'A' => 0,
                'B' => 1,
                'C',
                'E',
                => 2,
                'F' => 3,
                'G' => @as(u32, block: {
                    if (z >= 1454) break :block 5;
                    break :block 4;
                }),
                'H' => 5,
                'I' => 6,
                'J',
                'K',
                'N',
                => 7,
                'L' => 8,
                'P' => 9,
                'R' => 10,
                'S' => 11,
                else => return error.InvalidVersion,
            }),
            5 => @as(u32, switch (y) { // Leopard: 10.5
                'A' => 0,
                'B' => 1,
                'C' => 2,
                'D' => 3,
                'E' => 4,
                'F' => 5,
                'G' => 6,
                'J' => 7,
                'L' => 8,
                else => return error.InvalidVersion,
            }),
            6 => @as(u32, switch (y) { // Snow Leopard: 10.6
                'A' => 0,
                'B' => 1,
                'C' => 2,
                'D' => 3,
                'F' => 4,
                'H' => 5,
                'J' => @as(u32, block: {
                    if (z < 869) break :block 6;
                    break :block 7;
                }),
                'K' => 8,
                else => return error.InvalidVersion,
            }),
            7 => @as(u32, switch (y) { // Snow Leopard: 10.6
                'A' => 0,
                'B' => 1,
                'C' => 2,
                'D' => 3,
                'E' => 4,
                'G' => 5,
                else => return error.InvalidVersion,
            }),
            else => y - 'A',
        };
    }
    return result;
}

test "version_from_build" {
    // see https://en.wikipedia.org/wiki/MacOS_version_history#Releases
    const known = [_][2][]const u8{
        .{ "4K78", "10.0.0" },
        .{ "4L13", "10.0.1" },
        .{ "4P12", "10.0.2" },
        .{ "4P13", "10.0.3" },
        .{ "4Q12", "10.0.4" },

        .{ "5G64", "10.1.0" },
        .{ "5M28", "10.1.1" },
        .{ "5P48", "10.1.2" },
        .{ "5Q45", "10.1.3" },
        .{ "5Q125", "10.1.4" },
        .{ "5S60", "10.1.5" },

        .{ "6C115", "10.2.0" },
        .{ "6C115a", "10.2.0" },
        .{ "6D52", "10.2.1" },
        .{ "6F21", "10.2.2" },
        .{ "6G30", "10.2.3" },
        .{ "6G37", "10.2.3" },
        .{ "6G50", "10.2.3" },
        .{ "6I32", "10.2.4" },
        .{ "6L29", "10.2.5" },
        .{ "6L60", "10.2.6" },
        .{ "6R65", "10.2.7" },
        .{ "6R73", "10.2.8" },
        .{ "6S90", "10.2.8" },

        .{ "7B85", "10.3.0" },
        .{ "7B86", "10.3.0" },
        .{ "7C107", "10.3.1" },
        .{ "7D24", "10.3.2" },
        .{ "7D28", "10.3.2" },
        .{ "7F44", "10.3.3" },
        .{ "7H63", "10.3.4" },
        .{ "7M34", "10.3.5" },
        .{ "7R28", "10.3.6" },
        .{ "7S215", "10.3.7" },
        .{ "7U16", "10.3.8" },
        .{ "7W98", "10.3.9" },

        .{ "8A428", "10.4.0" },
        .{ "8A432", "10.4.0" },
        .{ "8B15", "10.4.1" },
        .{ "8B17", "10.4.1" },
        .{ "8C46", "10.4.2" },
        .{ "8C47", "10.4.2" },
        .{ "8E102", "10.4.2" },
        .{ "8E45", "10.4.2" },
        .{ "8E90", "10.4.2" },
        .{ "8F46", "10.4.3" },
        .{ "8G32", "10.4.4" },
        .{ "8G1165", "10.4.4" },
        .{ "8H14", "10.4.5" },
        .{ "8G1454", "10.4.5" },
        .{ "8I127", "10.4.6" },
        .{ "8I1119", "10.4.6" },
        .{ "8J135", "10.4.7" },
        .{ "8J2135a", "10.4.7" },
        .{ "8K1079", "10.4.7" },
        .{ "8N5107", "10.4.7" },
        .{ "8L127", "10.4.8" },
        .{ "8L2127", "10.4.8" },
        .{ "8P135", "10.4.9" },
        .{ "8P2137", "10.4.9" },
        .{ "8R218", "10.4.10" },
        .{ "8R2218", "10.4.10" },
        .{ "8R2232", "10.4.10" },
        .{ "8S165", "10.4.11" },
        .{ "8S2167", "10.4.11" },

        .{ "9A581", "10.5.0" },
        .{ "9B18", "10.5.1" },
        .{ "9C31", "10.5.2" },
        .{ "9C7010", "10.5.2" },
        .{ "9D34", "10.5.3" },
        .{ "9E17", "10.5.4" },
        .{ "9F33", "10.5.5" },
        .{ "9G55", "10.5.6" },
        .{ "9G66", "10.5.6" },
        .{ "9J61", "10.5.7" },
        .{ "9L30", "10.5.8" },

        .{ "10A432", "10.6.0" },
        .{ "10A433", "10.6.0" },
        .{ "10B504", "10.6.1" },
        .{ "10C540", "10.6.2" },
        .{ "10D573", "10.6.3" },
        .{ "10D575", "10.6.3" },
        .{ "10D578", "10.6.3" },
        .{ "10F569", "10.6.4" },
        .{ "10H574", "10.6.5" },
        .{ "10J567", "10.6.6" },
        .{ "10J869", "10.6.7" },
        .{ "10J3250", "10.6.7" },
        .{ "10J4138", "10.6.7" },
        .{ "10K540", "10.6.8" },
        .{ "10K549", "10.6.8" },

        .{ "11A511", "10.7.0" },
        .{ "11A511s", "10.7.0" },
        .{ "11A2061", "10.7.0" },
        .{ "11A2063", "10.7.0" },
        .{ "11B26", "10.7.1" },
        .{ "11B2118", "10.7.1" },
        .{ "11C74", "10.7.2" },
        .{ "11D50", "10.7.3" },
        .{ "11E53", "10.7.4" },
        .{ "11G56", "10.7.5" },
        .{ "11G63", "10.7.5" },

        .{ "12A269", "10.8.0" },
        .{ "12B19", "10.8.1" },
        .{ "12C54", "10.8.2" },
        .{ "12C60", "10.8.2" },
        .{ "12C2034", "10.8.2" },
        .{ "12C3104", "10.8.2" },
        .{ "12D78", "10.8.3" },
        .{ "12E55", "10.8.4" },
        .{ "12E3067", "10.8.4" },
        .{ "12E4022", "10.8.4" },
        .{ "12F37", "10.8.5" },
        .{ "12F45", "10.8.5" },
        .{ "12F2501", "10.8.5" },
        .{ "12F2518", "10.8.5" },
        .{ "12F2542", "10.8.5" },
        .{ "12F2560", "10.8.5" },

        .{ "13A603", "10.9.0" },
        .{ "13B42", "10.9.1" },
        .{ "13C64", "10.9.2" },
        .{ "13C1021", "10.9.2" },
        .{ "13D65", "10.9.3" },
        .{ "13E28", "10.9.4" },
        .{ "13F34", "10.9.5" },
        .{ "13F1066", "10.9.5" },
        .{ "13F1077", "10.9.5" },
        .{ "13F1096", "10.9.5" },
        .{ "13F1112", "10.9.5" },
        .{ "13F1134", "10.9.5" },
        .{ "13F1507", "10.9.5" },
        .{ "13F1603", "10.9.5" },
        .{ "13F1712", "10.9.5" },
        .{ "13F1808", "10.9.5" },
        .{ "13F1911", "10.9.5" },

        .{ "14A389", "10.10.0" },
        .{ "14B25", "10.10.1" },
        .{ "14C109", "10.10.2" },
        .{ "14C1510", "10.10.2" },
        .{ "14C1514", "10.10.2" },
        .{ "14C2043", "10.10.2" },
        .{ "14C2513", "10.10.2" },
        .{ "14D131", "10.10.3" },
        .{ "14D136", "10.10.3" },
        .{ "14E46", "10.10.4" },
        .{ "14F27", "10.10.5" },
        .{ "14F1021", "10.10.5" },
        .{ "14F1505", "10.10.5" },
        .{ "14F1509", "10.10.5" },
        .{ "14F1605", "10.10.5" },
        .{ "14F1713", "10.10.5" },
        .{ "14F1808", "10.10.5" },
        .{ "14F1909", "10.10.5" },
        .{ "14F1912", "10.10.5" },
        .{ "14F2009", "10.10.5" },
        .{ "14F2109", "10.10.5" },
        .{ "14F2315", "10.10.5" },
        .{ "14F2411", "10.10.5" },
        .{ "14F2511", "10.10.5" },

        .{ "15A284", "10.11.0" },
        .{ "15B42", "10.11.1" },
        .{ "15C50", "10.11.2" },
        .{ "15D21", "10.11.3" },
        .{ "15E65", "10.11.4" },
        .{ "15F34", "10.11.5" },
        .{ "15G31", "10.11.6" },
        .{ "15G1004", "10.11.6" },
        .{ "15G1011", "10.11.6" },
        .{ "15G1108", "10.11.6" },
        .{ "15G1212", "10.11.6" },
        .{ "15G1217", "10.11.6" },
        .{ "15G1421", "10.11.6" },
        .{ "15G1510", "10.11.6" },
        .{ "15G1611", "10.11.6" },
        .{ "15G17023", "10.11.6" },
        .{ "15G18013", "10.11.6" },
        .{ "15G19009", "10.11.6" },
        .{ "15G20015", "10.11.6" },
        .{ "15G21013", "10.11.6" },
        .{ "15G22010", "10.11.6" },

        .{ "16A323", "10.12.0" },
        .{ "16B2555", "10.12.1" },
        .{ "16B2657", "10.12.1" },
        .{ "16C67", "10.12.2" },
        .{ "16C68", "10.12.2" },
        .{ "16D32", "10.12.3" },
        .{ "16E195", "10.12.4" },
        .{ "16F73", "10.12.5" },
        .{ "16F2073", "10.12.5" },
        .{ "16G29", "10.12.6" },
        .{ "16G1036", "10.12.6" },
        .{ "16G1114", "10.12.6" },
        .{ "16G1212", "10.12.6" },
        .{ "16G1314", "10.12.6" },
        .{ "16G1408", "10.12.6" },
        .{ "16G1510", "10.12.6" },
        .{ "16G1618", "10.12.6" },
        .{ "16G1710", "10.12.6" },
        .{ "16G1815", "10.12.6" },
        .{ "16G1917", "10.12.6" },
        .{ "16G1918", "10.12.6" },
        .{ "16G2016", "10.12.6" },
        .{ "16G2127", "10.12.6" },
        .{ "16G2128", "10.12.6" },
        .{ "16G2136", "10.12.6" },

        .{ "17A365", "10.13.0" },
        .{ "17A405", "10.13.0" },
        .{ "17B48", "10.13.1" },
        .{ "17B1002", "10.13.1" },
        .{ "17B1003", "10.13.1" },
        .{ "17C88", "10.13.2" },
        .{ "17C89", "10.13.2" },
        .{ "17C205", "10.13.2" },
        .{ "17C2205", "10.13.2" },
        .{ "17D47", "10.13.3" },
        .{ "17D2047", "10.13.3" },
        .{ "17D102", "10.13.3" },
        .{ "17D2102", "10.13.3" },
        .{ "17E199", "10.13.4" },
        .{ "17E202", "10.13.4" },
        .{ "17F77", "10.13.5" },
        .{ "17G65", "10.13.6" },
        .{ "17G2208", "10.13.6" },
        .{ "17G3025", "10.13.6" },
        .{ "17G4015", "10.13.6" },
        .{ "17G5019", "10.13.6" },
        .{ "17G6029", "10.13.6" },
        .{ "17G6030", "10.13.6" },
        .{ "17G7024", "10.13.6" },
        .{ "17G8029", "10.13.6" },
        .{ "17G8030", "10.13.6" },
        .{ "17G8037", "10.13.6" },
        .{ "17G9016", "10.13.6" },
        .{ "17G10021", "10.13.6" },
        .{ "17G11023", "10.13.6" },
        .{ "17G12034", "10.13.6" },

        .{ "18A391", "10.14.0" },
        .{ "18B75", "10.14.1" },
        .{ "18B2107", "10.14.1" },
        .{ "18B3094", "10.14.1" },
        .{ "18C54", "10.14.2" },
        .{ "18D42", "10.14.3" },
        .{ "18D43", "10.14.3" },
        .{ "18D109", "10.14.3" },
        .{ "18E226", "10.14.4" },
        .{ "18E227", "10.14.4" },
        .{ "18F132", "10.14.5" },
        .{ "18G84", "10.14.6" },
        .{ "18G87", "10.14.6" },
        .{ "18G95", "10.14.6" },
        .{ "18G103", "10.14.6" },
        .{ "18G1012", "10.14.6" },
        .{ "18G2022", "10.14.6" },
        .{ "18G3020", "10.14.6" },
        .{ "18G4032", "10.14.6" },

        .{ "19A583", "10.15.0" },
        .{ "19A602", "10.15.0" },
        .{ "19A603", "10.15.0" },
        .{ "19B88", "10.15.1" },
        .{ "19C57", "10.15.2" },
        .{ "19D76", "10.15.3" },
        .{ "19E266", "10.15.4" },
        .{ "19E287", "10.15.4" },
    };
    for (known) |pair| {
        var buf: [32]u8 = undefined;
        const ver = try version_from_build(pair[0]);
        const sver = try std.fmt.bufPrint(buf[0..], "{}.{}.{}", .{ ver.major, ver.minor, ver.patch });
        std.testing.expect(std.mem.eql(u8, sver, pair[1]));
    }
}

/// Detect SDK path on Darwin.
/// Calls `xcrun --show-sdk-path` which result can be used to specify
/// `-syslibroot` param of the linker.
/// The caller needs to free the resulting path slice.
pub fn getSDKPath(allocator: *mem.Allocator) ![]u8 {
    assert(std.Target.current.isDarwin());
    const argv = &[_][]const u8{ "/usr/bin/xcrun", "--show-sdk-path" };
    const result = try std.ChildProcess.exec(.{ .allocator = allocator, .argv = argv });
    defer {
        allocator.free(result.stderr);
        allocator.free(result.stdout);
    }
    if (result.stderr.len != 0) {
        std.log.err("unexpected 'xcrun --show-sdk-path' stderr: {}", .{result.stderr});
    }
    if (result.term.Exited != 0) {
        return error.ProcessTerminated;
    }
    const syslibroot = mem.trimRight(u8, result.stdout, "\r\n");
    return mem.dupe(allocator, u8, syslibroot);
}
