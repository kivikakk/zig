pub const Md5 = @import("crypto/md5.zig").Md5;
pub const Sha1 = @import("crypto/sha1.zig").Sha1;

const sha2 = @import("crypto/sha2.zig");
pub const Sha224 = sha2.Sha224;
pub const Sha256 = sha2.Sha256;
pub const Sha384 = sha2.Sha384;
pub const Sha512 = sha2.Sha512;

const sha3 = @import("crypto/sha3.zig");
pub const Sha3_224 = sha3.Sha3_224;
pub const Sha3_256 = sha3.Sha3_256;
pub const Sha3_384 = sha3.Sha3_384;
pub const Sha3_512 = sha3.Sha3_512;

pub const gimli = @import("crypto/gimli.zig");

const blake2 = @import("crypto/blake2.zig");
pub const Blake2s224 = blake2.Blake2s224;
pub const Blake2s256 = blake2.Blake2s256;
pub const Blake2b384 = blake2.Blake2b384;
pub const Blake2b512 = blake2.Blake2b512;

pub const Blake3 = @import("crypto/blake3.zig").Blake3;

const hmac = @import("crypto/hmac.zig");
pub const HmacMd5 = hmac.HmacMd5;
pub const HmacSha1 = hmac.HmacSha1;
pub const HmacSha256 = hmac.HmacSha256;
pub const HmacBlake2s256 = hmac.HmacBlake2s256;

pub const chacha20 = @import("crypto/chacha20.zig");
pub const chaCha20IETF = chacha20.chaCha20IETF;
pub const chaCha20With64BitNonce = chacha20.chaCha20With64BitNonce;
pub const xChaCha20IETF = chacha20.xChaCha20IETF;

pub const Poly1305 = @import("crypto/poly1305.zig").Poly1305;

const import_aes = @import("crypto/aes.zig");
pub const AES128 = import_aes.AES128;
pub const AES256 = import_aes.AES256;

pub const Curve25519 = @import("crypto/25519/curve25519.zig").Curve25519;
pub const Ed25519 = @import("crypto/25519/ed25519.zig").Ed25519;
pub const Edwards25519 = @import("crypto/25519/edwards25519.zig").Edwards25519;
pub const X25519 = @import("crypto/25519/x25519.zig").X25519;
pub const Ristretto255 = @import("crypto/25519/ristretto255.zig").Ristretto255;

pub const aead = struct {
    pub const Gimli = gimli.Aead;
    pub const ChaCha20Poly1305 = chacha20.Chacha20Poly1305;
    pub const XChaCha20Poly1305 = chacha20.XChacha20Poly1305;
};

const std = @import("std.zig");
pub const randomBytes = std.os.getrandom;

test "crypto" {
    _ = @import("crypto/aes.zig");
    _ = @import("crypto/blake2.zig");
    _ = @import("crypto/blake3.zig");
    _ = @import("crypto/chacha20.zig");
    _ = @import("crypto/gimli.zig");
    _ = @import("crypto/hmac.zig");
    _ = @import("crypto/md5.zig");
    _ = @import("crypto/poly1305.zig");
    _ = @import("crypto/sha1.zig");
    _ = @import("crypto/sha2.zig");
    _ = @import("crypto/sha3.zig");
    _ = @import("crypto/25519/curve25519.zig");
    _ = @import("crypto/25519/ed25519.zig");
    _ = @import("crypto/25519/edwards25519.zig");
    _ = @import("crypto/25519/field.zig");
    _ = @import("crypto/25519/scalar.zig");
    _ = @import("crypto/25519/x25519.zig");
    _ = @import("crypto/25519/ristretto255.zig");
}

test "issue #4532: no index out of bounds" {
    const types = [_]type{
        Md5,
        Sha1,
        Sha224,
        Sha256,
        Sha384,
        Sha512,
        Blake2s224,
        Blake2s256,
        Blake2b384,
        Blake2b512,
    };

    inline for (types) |Hasher| {
        var block = [_]u8{'#'} ** Hasher.block_length;
        var out1: [Hasher.digest_length]u8 = undefined;
        var out2: [Hasher.digest_length]u8 = undefined;

        var h = Hasher.init();
        h.update(block[0..]);
        h.final(out1[0..]);
        h.reset();
        h.update(block[0..1]);
        h.update(block[1..]);
        h.final(out2[0..]);

        std.testing.expectEqual(out1, out2);
    }
}
