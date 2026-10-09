//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import NetworkingTypes
import Testing

#if canImport(Darwin)
import Darwin
#endif

@Suite
struct IPAddressTests {
    @Test func `IPv4Address stores its bytes in order`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        let address = IPv4Address(192, 168, 1, 1)
        #expect(address[byte: 0] == 192)
        #expect(address[byte: 1] == 168)
        #expect(address[byte: 2] == 1)
        #expect(address[byte: 3] == 1)
    }

    @Test func `IPv4Address converts to and from its numeric value`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        let loopback = IPv4Address(127, 0, 0, 1)
        #expect(loopback.numericValue == 0x7F00_0001)
        #expect(IPv4Address(numericValue: 0x7F00_0001) == loopback)
        #expect(IPv4Address(numericValue: 0xC0A8_0101) == IPv4Address(192, 168, 1, 1))
        #expect(IPv4Address(numericValue: .max) == IPv4Address(255, 255, 255, 255))
        #expect(IPv4Address(numericValue: 0) == IPv4Address(0, 0, 0, 0))
    }

    @Test func `IPv4Address is created from a network-order integer`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        // Like `in_addr.s_addr`, the integer holds the address's bytes in order in memory.
        var raw: UInt32 = 0
        withUnsafeMutableBytes(of: &raw) { $0.copyBytes(from: [192, 168, 1, 2] as [UInt8]) }
        #expect(IPv4Address(networkOrder: raw) == IPv4Address(192, 168, 1, 2))

        #expect(IPv4Address(networkOrder: UInt32(0x7F00_0001).bigEndian) == .loopback)
        #expect(IPv4Address(networkOrder: 0) == .any)
        #expect(IPv4Address(networkOrder: .max) == .broadcast)
    }

    @Test func `IPv4Address equality and hashing compare every byte`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        let address = IPv4Address(10, 0, 0, 1)
        #expect(address == IPv4Address(10, 0, 0, 1))
        #expect(address != IPv4Address(10, 0, 0, 2))
        #expect(address != IPv4Address(11, 0, 0, 1))
        #expect(Set([address, IPv4Address(10, 0, 0, 1), IPv4Address(10, 0, 0, 2)]).count == 2)
    }

    @Test func `IPv6Address splits segments into bytes in order`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        let address = IPv6Address(0x2001, 0x0DB8, 0x1234, 0x5678, 0x9ABC, 0xDEF0, 0x0F0F, 0xFF01)
        let expected: [UInt8] = [
            0x20, 0x01, 0x0D, 0xB8, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0, 0x0F, 0x0F, 0xFF, 0x01,
        ]
        for (index, byte) in expected.enumerated() {
            #expect(address[byte: index] == byte)
        }
    }

    @Test func `IPv6Address converts to and from its numeric value`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        let documentation = IPv6Address(0x2001, 0x0DB8, 0, 0, 0, 0, 0, 1)
        #expect(documentation.numericValue == 0x2001_0DB8_0000_0000_0000_0000_0000_0001)
        #expect(IPv6Address(numericValue: 0x2001_0DB8_0000_0000_0000_0000_0000_0001) == documentation)
        #expect(IPv6Address(numericValue: 1) == IPv6Address(0, 0, 0, 0, 0, 0, 0, 1))
        #expect(IPv6Address(numericValue: 0) == IPv6Address(0, 0, 0, 0, 0, 0, 0, 0))
        let all = IPv6Address(numericValue: .max)
        #expect(all == IPv6Address(0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF))
        #expect(all.numericValue == .max)

        let mixed = IPv6Address(0x2001, 0x0DB8, 0x1234, 0x5678, 0x9ABC, 0xDEF0, 0x0F0F, 0xFF01)
        #expect(mixed.numericValue == 0x2001_0DB8_1234_5678_9ABC_DEF0_0F0F_FF01)
        #expect(IPv6Address(numericValue: mixed.numericValue) == mixed)
    }

    @Test func `IPv6Address is created from network-order integers`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        // Like `in6_addr`, the integers hold the address's bytes in order in memory.
        let bytes: [UInt8] = [
            0x20, 0x01, 0x0D, 0xB8, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0, 0x0F, 0x0F, 0xFF, 0x01,
        ]
        var raw: (UInt32, UInt32, UInt32, UInt32) = (0, 0, 0, 0)
        withUnsafeMutableBytes(of: &raw) { $0.copyBytes(from: bytes) }
        #expect(
            IPv6Address(networkOrder: raw)
                == IPv6Address(0x2001, 0x0DB8, 0x1234, 0x5678, 0x9ABC, 0xDEF0, 0x0F0F, 0xFF01)
        )

        #expect(IPv6Address(networkOrder: (0, 0, 0, UInt32(1).bigEndian)) == .loopback)
        #expect(IPv6Address(networkOrder: (0, 0, 0, 0)) == .any)
        #expect(IPv6Address(networkOrder: (.max, .max, .max, .max)).numericValue == .max)
    }

    @Test func `IPv6Address equality and hashing compare every byte`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        let loopback = IPv6Address(0, 0, 0, 0, 0, 0, 0, 1)
        let unspecified = IPv6Address(0, 0, 0, 0, 0, 0, 0, 0)
        #expect(loopback[byte: 15] == 1)
        #expect(loopback == IPv6Address(0, 0, 0, 0, 0, 0, 0, 1))
        #expect(loopback != unspecified)
        #expect(loopback != IPv6Address(1, 0, 0, 0, 0, 0, 0, 1))
        #expect(Set([loopback, unspecified, unspecified]).count == 2)
    }

    @Test func `IPAddress distinguishes v4 and v6`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        let v4 = IPAddress.v4(IPv4Address(127, 0, 0, 1))
        let v6 = IPAddress.v6(IPv6Address(0, 0, 0, 0, 0, 0, 0, 1))
        #expect(v4 == .v4(IPv4Address(127, 0, 0, 1)))
        #expect(v4 != v6)
    }

    @Test func `Addresses are created from a Span of exactly the right number of bytes`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        let v4Bytes: [UInt8] = [192, 168, 1, 1]
        #expect(IPv4Address(bytes: v4Bytes.span) == IPv4Address(192, 168, 1, 1))

        let v6Bytes: [UInt8] = [0x20, 0x01, 0x0D, 0xB8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x01]
        #expect(IPv6Address(bytes: v6Bytes.span) == IPv6Address(0x2001, 0x0DB8, 0, 0, 0, 0, 0, 1))

        for count in [0, 1, 3, 5, 16] {
            let bytes = [UInt8](repeating: 1, count: count)
            #expect(IPv4Address(bytes: bytes.span) == nil)
        }
        for count in [0, 1, 4, 15, 17, 32] {
            let bytes = [UInt8](repeating: 1, count: count)
            #expect(IPv6Address(bytes: bytes.span) == nil)
        }
    }

    @Test func `withBytes gives the bytes in network byte order`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        let v4 = IPv4Address(192, 168, 1, 2)
        #expect(v4.withBytes { span in (0..<span.count).map { span[$0] } } == [192, 168, 1, 2])
        #expect(v4.withBytes { IPv4Address(bytes: $0) } == v4)

        let v6 = IPv6Address(0x2001, 0x0DB8, 0x1234, 0x5678, 0x9ABC, 0xDEF0, 0x0F0F, 0xFF01)
        #expect(
            v6.withBytes { span in (0..<span.count).map { span[$0] } } == [
                0x20, 0x01, 0x0D, 0xB8, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0, 0x0F, 0x0F, 0xFF, 0x01,
            ]
        )
        #expect(v6.withBytes { IPv6Address(bytes: $0) } == v6)
    }

    @Test func `Static addresses have the expected values`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        #expect(IPv4Address.loopback == IPv4Address(127, 0, 0, 1))
        #expect(IPv4Address.any == IPv4Address(0, 0, 0, 0))
        #expect(IPv4Address.broadcast == IPv4Address(255, 255, 255, 255))
        #expect(IPv6Address.loopback.numericValue == 1)
        #expect(IPv6Address.any.numericValue == 0)
    }

    @Test(
        arguments: [
            ("0.0.0.0", [0, 0, 0, 0]),
            ("127.0.0.1", [127, 0, 0, 1]),
            ("192.168.1.1", [192, 168, 1, 1]),
            ("10.0.0.255", [10, 0, 0, 255]),
            ("255.255.255.255", [255, 255, 255, 255]),
        ] as [(String, [UInt8])]
    )
    func `IPv4Address parses and prints dotted-decimal text`(text: String, bytes: [UInt8]) {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        let address = IPv4Address(bytes[0], bytes[1], bytes[2], bytes[3])
        #expect(IPv4Address(text) == address)
        #expect(address.description == text)
    }

    @Test(
        arguments: [
            "", ".", "...", "1.2.3", "1.2.3.4.5", "1..2.3", ".1.2.3", "1.2.3.", "256.0.0.1", "1.2.3.256",
            "1000.1.1.1", "01.2.3.4", "1.2.3.04", "00.0.0.0", "1.2.3.4 ", " 1.2.3.4", "+1.2.3.4", "1.2.3.-4",
            "a.b.c.d", "1.2.3.4/24", "0x7f.0.0.1", "1.2.3.4\0", "١.٢.٣.٤",
        ]
    )
    func `IPv4Address rejects invalid text`(text: String) {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        #expect(IPv4Address(text) == nil)
    }

    @Test func `IPv4Address round-trips every byte value through text in every position`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        for value in UInt8.min...UInt8.max {
            for address in [
                IPv4Address(value, 1, 2, 3), IPv4Address(1, value, 2, 3),
                IPv4Address(1, 2, value, 3), IPv4Address(1, 2, 3, value),
            ] {
                #expect(IPv4Address(address.description) == address)
            }
        }
    }

    @Test(
        arguments: [
            // Zero compression.
            ([0, 0, 0, 0, 0, 0, 0, 0], "::"),
            ([0, 0, 0, 0, 0, 0, 0, 1], "::1"),
            ([1, 0, 0, 0, 0, 0, 0, 0], "1::"),
            ([0x2001, 0x0DB8, 0, 0, 0, 0, 0, 1], "2001:db8::1"),
            ([0xFE80, 0, 0, 0, 0, 0, 0, 1], "fe80::1"),
            // RFC 5952 Section 4.2.2: a single zero segment is not compressed.
            ([0x2001, 0x0DB8, 0, 1, 1, 1, 1, 1], "2001:db8:0:1:1:1:1:1"),
            // RFC 5952 Section 4.2.3: the longest run is compressed, and the first one on a tie.
            ([0x2001, 0, 0, 1, 0, 0, 0, 1], "2001:0:0:1::1"),
            ([0x2001, 0x0DB8, 0, 0, 1, 0, 0, 1], "2001:db8::1:0:0:1"),
            // No zeros to compress.
            ([1, 2, 3, 4, 5, 6, 7, 8], "1:2:3:4:5:6:7:8"),
            (
                [0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF],
                "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"
            ),
            // RFC 5952 Sections 4.1 and 4.3: leading zeros are omitted and letters are lowercase.
            ([0x2001, 0x0DB8, 0x00AB, 0x0C0D, 0xEF01, 0x0002, 0x0030, 0x0400], "2001:db8:ab:c0d:ef01:2:30:400"),
            // RFC 5952 Section 5: IPv4-mapped addresses use dotted-decimal for the last 32 bits.
            ([0, 0, 0, 0, 0, 0xFFFF, 0xC000, 0x0201], "::ffff:192.0.2.1"),
            ([0, 0, 0, 0, 0, 0xFFFF, 0, 0], "::ffff:0.0.0.0"),
            // Close to IPv4-mapped, but not.
            ([0, 0, 0, 0, 0, 0xFFFE, 0xC000, 0x0201], "::fffe:c000:201"),
            ([0, 0, 0, 0, 1, 0xFFFF, 0xC000, 0x0201], "::1:ffff:c000:201"),
            ([1, 0, 0, 0, 0, 0xFFFF, 0xC000, 0x0201], "1::ffff:c000:201"),
        ] as [([UInt16], String)]
    )
    func `IPv6Address prints and parses its RFC 5952 textual representation`(segments: [UInt16], text: String) {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        let address = IPv6Address(
            segments[0],
            segments[1],
            segments[2],
            segments[3],
            segments[4],
            segments[5],
            segments[6],
            segments[7]
        )
        #expect(address.description == text)
        #expect(IPv6Address(text) == address)
    }

    @Test(
        arguments: [
            // Not compressed, with and without leading zeros.
            ("0:0:0:0:0:0:0:0", [0, 0, 0, 0, 0, 0, 0, 0]),
            ("2001:0db8:0000:0000:0000:0000:0000:0001", [0x2001, 0x0DB8, 0, 0, 0, 0, 0, 1]),
            ("2001:db8:0:0:0:0:0:1", [0x2001, 0x0DB8, 0, 0, 0, 0, 0, 1]),
            // Uppercase and mixed case.
            ("2001:DB8::1", [0x2001, 0x0DB8, 0, 0, 0, 0, 0, 1]),
            ("FE80::AbCd", [0xFE80, 0, 0, 0, 0, 0, 0, 0xABCD]),
            // `::` can stand for a single zero segment, at either end or in the middle.
            ("1:2:3:4:5:6:7::", [1, 2, 3, 4, 5, 6, 7, 0]),
            ("::2:3:4:5:6:7:8", [0, 2, 3, 4, 5, 6, 7, 8]),
            ("1:2:3::5:6:7:8", [1, 2, 3, 0, 5, 6, 7, 8]),
            // `::` that isn't the longest zero run, as RFC 5952 would print it.
            ("2001:db8::1:0:0:1", [0x2001, 0x0DB8, 0, 0, 1, 0, 0, 1]),
            ("2001:db8:0:0:1::1", [0x2001, 0x0DB8, 0, 0, 1, 0, 0, 1]),
            // An IPv4 suffix, with and without `::`.
            ("::ffff:192.0.2.1", [0, 0, 0, 0, 0, 0xFFFF, 0xC000, 0x0201]),
            ("0:0:0:0:0:ffff:192.0.2.1", [0, 0, 0, 0, 0, 0xFFFF, 0xC000, 0x0201]),
            ("64:ff9b::192.0.2.1", [0x64, 0xFF9B, 0, 0, 0, 0, 0xC000, 0x0201]),
            ("::1.2.3.4", [0, 0, 0, 0, 0, 0, 0x0102, 0x0304]),
            ("1:2:3:4:5:6:1.2.3.4", [1, 2, 3, 4, 5, 6, 0x0102, 0x0304]),
        ] as [(String, [UInt16])]
    )
    func `IPv6Address parses other valid textual representations`(text: String, segments: [UInt16]) {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        let address = IPv6Address(
            segments[0],
            segments[1],
            segments[2],
            segments[3],
            segments[4],
            segments[5],
            segments[6],
            segments[7]
        )
        #expect(IPv6Address(text) == address)
    }

    @Test(
        arguments: [
            // Empty or only colons.
            "", ":", ":::", "::::",
            // Stray single colons.
            ":1::", "1::2:", ":1:2:3:4:5:6:7:8", "1:2:3:4:5:6:7:8:", "1:2::3:", "1:::2",
            // More than one `::`.
            "1::2::3", "::1::", "::1:2::",
            // Too few or too many segments.
            "1:2:3:4:5:6:7", "1:2:3:4:5:6:7:8:9", "::1:2:3:4:5:6:7:8", "1:2:3:4::5:6:7:8",
            // Invalid segments.
            "12345::", "g::", "::g", "1:2:3:4:5:6:7:-8", "+1::", "::+1", "0x1::", "::١",
            // Whitespace.
            " ::1", "::1 ", ":: 1",
            // Things that aren't part of an address.
            "[::1]", "::1/128", "fe80::1%en0", "fe80::1%1",
            // Invalid IPv4 suffixes.
            "1.2.3.4", "::1.2.3", "::1.2.3.4.5", "::256.1.1.1", "::01.2.3.4", "1.2.3.4::", "::1.2.3.4:1",
            "1:2:3:4:5:6:7:1.2.3.4", "1:2:3:4:5:6:7:8.9", "1.2.3.4::1", "::1.2.3.4::",
        ]
    )
    func `IPv6Address rejects invalid text`(text: String) {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        #expect(IPv6Address(text) == nil)
    }

    /// Prints and parses back all 256 combinations of zero and non-zero segments, using non-zero values
    /// `0xab` and `0xffff`. With `0xffff` some of these are IPv4-mapped, so they print in mixed notation.
    @Test func `IPv6Address round-trips every pattern of zero segments through text`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        for nonZero: UInt16 in [0xAB, 0xFFFF] {
            for pattern in 0..<256 {
                let segments: [UInt16] = (0..<8).map { pattern & (1 << $0) == 0 ? 0 : nonZero }
                let address = IPv6Address(
                    segments[0],
                    segments[1],
                    segments[2],
                    segments[3],
                    segments[4],
                    segments[5],
                    segments[6],
                    segments[7]
                )
                #expect(IPv6Address(address.description) == address, "\(address) didn't round-trip")
            }
        }
    }

    @Test func `IPv6Address static addresses print as expected`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        #expect(IPv6Address.loopback.description == "::1")
        #expect(IPv6Address.any.description == "::")
    }

    /// Tries all 256 combinations of zero and non-zero segments, and checks each description against
    /// the RFC 5952 rules independently of how `description` is implemented.
    @Test func `IPv6Address compresses the longest zero run for every pattern of zero segments`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }

        // Splits text like `"ab:0:ab"` into its segment values. Returns `-1` for any invalid segment.
        func segmentValues(of text: Substring) -> [Int] {
            guard !text.isEmpty else {
                return []
            }
            return text.split(separator: ":", omittingEmptySubsequences: false).map { segment in
                // Segments must be lowercase hex without leading zeros.
                guard segment == "0" || !segment.hasPrefix("0"), segment.lowercased() == segment else {
                    return -1
                }
                return Int(segment, radix: 16) ?? -1
            }
        }

        for pattern in 0..<256 {
            // Bit `i` of `pattern` decides whether segment `i` is zero. `0xab` is never `0xffff`,
            // so none of these addresses are IPv4-mapped.
            let segments: [Int] = (0..<8).map { pattern & (1 << $0) == 0 ? 0 : 0xAB }
            let address = IPv6Address(
                UInt16(segments[0]),
                UInt16(segments[1]),
                UInt16(segments[2]),
                UInt16(segments[3]),
                UInt16(segments[4]),
                UInt16(segments[5]),
                UInt16(segments[6]),
                UInt16(segments[7])
            )
            let text = address.description

            // Expand `::` back into zeros, and record where it was and how many segments it replaced.
            var expanded: [Int]
            var compressedStart: Int?
            var compressedLength = 0
            if let range = text.firstRange(of: "::") {
                let head = segmentValues(of: text[..<range.lowerBound])
                let tail = segmentValues(of: text[range.upperBound...])
                #expect(text[range.upperBound...].firstRange(of: "::") == nil, "More than one :: in \(text)")
                compressedStart = head.count
                compressedLength = 8 - head.count - tail.count
                expanded = head + [Int](repeating: 0, count: max(compressedLength, 0)) + tail
            } else {
                expanded = segmentValues(of: text[...])
            }
            #expect(expanded == segments, "\(text) doesn't expand back to \(segments)")

            // Find the first longest run of zero segments by brute force.
            var longestStart = 0
            var longestLength = 0
            for start in 0..<8 {
                var length = 0
                while start + length < 8, segments[start + length] == 0 {
                    length += 1
                }
                if length > longestLength {
                    longestStart = start
                    longestLength = length
                }
            }

            if longestLength >= 2 {
                #expect(compressedStart == longestStart, "\(text) compressed the wrong run of \(segments)")
                #expect(compressedLength == longestLength, "\(text) compressed the wrong run of \(segments)")
            } else {
                #expect(compressedStart == nil, "\(text) compressed a run shorter than 2 in \(segments)")
            }
        }
    }
}

@Suite
struct IPAddressEnumTests {
    @Test func `IPAddress parses either version`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        #expect(IPAddress("192.168.1.1") == .v4(IPv4Address(192, 168, 1, 1)))
        #expect(IPAddress("2001:db8::1") == .v6(IPv6Address(0x2001, 0x0DB8, 0, 0, 0, 0, 0, 1)))
        #expect(IPAddress("::ffff:192.0.2.1") == .v6(IPv6Address(0, 0, 0, 0, 0, 0xFFFF, 0xC000, 0x0201)))
    }

    @Test(arguments: ["", "1.2.3", "256.1.1.1", "1::2::3", "[::1]", "::1/128", "example.com"])
    func `IPAddress rejects text that is neither version`(text: String) {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        #expect(IPAddress(text) == nil)
    }

    @Test func `IPAddress prints the address it holds`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        #expect(IPAddress.v4(IPv4Address(192, 168, 1, 1)).description == "192.168.1.1")
        #expect(IPAddress.v6(IPv6Address(0x2001, 0x0DB8, 0, 0, 0, 0, 0, 1)).description == "2001:db8::1")
        for text in ["0.0.0.0", "10.0.0.1", "::", "::1", "fe80::1", "::ffff:10.0.0.1"] {
            #expect(IPAddress(text)?.description == text)
        }
    }

    @Test func `IPAddress gives the address of the matching version only`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        let v4 = IPAddress.v4(.loopback)
        let v6 = IPAddress.v6(.loopback)
        #expect(v4.ipv4 == .loopback)
        #expect(v4.ipv6 == nil)
        #expect(v6.ipv4 == nil)
        #expect(v6.ipv6 == .loopback)
    }
}

#if canImport(Darwin)
@Suite
struct IPAddressCInteropTests {
    @Test func `Addresses are created from the integers in C address structs`() {
        guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) else { return }
        var v4 = in_addr()
        #expect(inet_pton(AF_INET, "192.0.2.1", &v4) == 1)
        #expect(IPv4Address(networkOrder: v4.s_addr) == IPv4Address(192, 0, 2, 1))

        var v6 = in6_addr()
        #expect(inet_pton(AF_INET6, "2001:db8::ffff:1", &v6) == 1)
        let words = withUnsafeBytes(of: v6) { $0.loadUnaligned(as: (UInt32, UInt32, UInt32, UInt32).self) }
        #expect(IPv6Address(networkOrder: words) == IPv6Address(0x2001, 0x0DB8, 0, 0, 0, 0, 0xFFFF, 1))
    }
}
#endif
