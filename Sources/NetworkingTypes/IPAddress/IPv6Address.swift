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

/// An IPv6 address.
///
/// IPv6 addresses are 128-bit values, made of 16 bytes in network byte order (most significant byte first),
/// as defined in [IETF RFC 4291].
///
/// [IETF RFC 4291]: https://datatracker.ietf.org/doc/html/rfc4291
@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
public struct IPv6Address: Sendable {
    /// The 16 bytes of the address, in network byte order.
    /// For example `::1` is fifteen `0` bytes followed by a `1`.
    private let bytes: [16 of UInt8]

    /// Creates a new address from its 8 16-bit segments, most significant segment first.
    /// This matches how IPv6 addresses are written, so for example
    /// `IPv6Address(0x2001, 0x0DB8, 0, 0, 0, 0, 0, 1)` is `2001:db8::1`.
    public init(
        _ first: UInt16,
        _ second: UInt16,
        _ third: UInt16,
        _ fourth: UInt16,
        _ fifth: UInt16,
        _ sixth: UInt16,
        _ seventh: UInt16,
        _ eighth: UInt16
    ) {
        let segments: [8 of UInt16] = [first, second, third, fourth, fifth, sixth, seventh, eighth]
        self.bytes = .init { index in
            let segment = segments[index / 2]
            // Even indices hold a segment's high byte and odd indices its low byte.
            return UInt8(truncatingIfNeeded: index % 2 == 0 ? segment >> 8 : segment)
        }
    }

    /// Creates a new address from its 16 bytes, in network byte order.
    /// Returns `nil` unless `bytes` contains exactly 16 bytes.
    public init?(bytes: Span<UInt8>) {
        guard bytes.count == 16 else {
            return nil
        }
        self.bytes = .init { index in bytes[index] }
    }

    /// Creates a new address from its numeric value, in host byte order.
    /// For example `IPv6Address(numericValue: 1)` is `::1`.
    public init(numericValue: UInt128) {
        self.bytes = .init { index in
            // Index `0` is the most significant byte, so it comes from the top 8 bits.
            UInt8(truncatingIfNeeded: numericValue >> (8 * (15 - index)))
        }
    }

    /// Creates a new address from four 32-bit integers in network byte order.
    ///
    /// In memory, each integer holds 4 of the address's bytes in order, so their numeric values depend on
    /// the platform's byte order. To create an address from a number, use `init(numericValue:)` instead.
    public init(networkOrder: (UInt32, UInt32, UInt32, UInt32)) {
        let words: [4 of UInt32] = [
            UInt32(bigEndian: networkOrder.0),
            UInt32(bigEndian: networkOrder.1),
            UInt32(bigEndian: networkOrder.2),
            UInt32(bigEndian: networkOrder.3),
        ]
        self.bytes = .init { index in
            // Each word holds 4 bytes, most significant first.
            UInt8(truncatingIfNeeded: words[index / 4] >> (8 * (3 - index % 4)))
        }
    }

    /// The byte at `index`, in network byte order. `index` must be in `0..<16`.
    /// For example the byte at index `15` of `::1` is `1`.
    public subscript(byte index: Int) -> UInt8 {
        self.bytes[index]
    }

    /// The numeric value of the address.
    /// For example the numeric value of `2001:db8::1` is `0x2001_0DB8_0000_0000_0000_0000_0000_0001`.
    public var numericValue: UInt128 {
        var value: UInt128 = 0
        for index in self.bytes.indices {
            value = value << 8 | UInt128(self.bytes[index])
        }
        return value
    }

    /// Calls `body` with a `Span` of the address's 16 bytes, in network byte order.
    public func withBytes<Result>(_ body: (Span<UInt8>) throws -> Result) rethrows -> Result {
        try body(self.bytes.span)
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension IPv6Address {
    /// The loopback address, `::1`.
    public static let loopback = IPv6Address(0, 0, 0, 0, 0, 0, 0, 1)

    /// The unspecified address, `::`.
    public static let any = IPv6Address(0, 0, 0, 0, 0, 0, 0, 0)
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension IPv6Address: LosslessStringConvertible {
    /// The textual representation of the address, as recommended by [IETF RFC 5952].
    ///
    /// - Hexadecimal digits are lowercase, and leading zeros in each segment are omitted.
    /// - The longest run of two or more zero segments is replaced with `::`. If there is a tie, the first run is.
    /// - IPv4-mapped addresses print their last 32 bits in dotted-decimal notation.
    ///
    /// For example `"2001:db8::1"`, `"::1"`, or `"::ffff:192.0.2.1"`.
    ///
    /// [IETF RFC 5952]: https://datatracker.ietf.org/doc/html/rfc5952
    public var description: String {
        if self.isIPv4Mapped {
            let ipv4 = IPv4Address(self.bytes[12], self.bytes[13], self.bytes[14], self.bytes[15])
            return "::ffff:\(ipv4)"
        }

        // Find the longest run of zero segments. `>` rather than `>=` keeps the first run on a tie.
        var longestRunStart = 0
        var longestRunLength = 0
        var runStart = 0
        for index in 0..<8 {
            if self.segment(at: index) != 0 {
                runStart = index + 1
            } else if index - runStart + 1 > longestRunLength {
                longestRunStart = runStart
                longestRunLength = index - runStart + 1
            }
        }

        var result = ""
        var index = 0
        while index < 8 {
            // RFC 5952 Section 4.2.2: a single zero segment is not replaced with `::`.
            if index == longestRunStart, longestRunLength >= 2 {
                result += "::"
                index += longestRunLength
                continue
            }
            if !result.isEmpty, !result.hasSuffix(":") {
                result += ":"
            }
            result += String(self.segment(at: index), radix: 16)
            index += 1
        }
        return result
    }

    /// Creates a new address from its textual representation, as defined in
    /// [IETF RFC 4291 Section 2.2](https://datatracker.ietf.org/doc/html/rfc4291#section-2.2).
    ///
    /// That is, 8 segments of 1 to 4 hexadecimal digits separated by `:`, for example
    /// `"2001:db8:0:0:0:0:0:1"`, where:
    /// - Hexadecimal digits can be uppercase or lowercase.
    /// - One run of zero segments can be replaced with `::`, for example `"2001:db8::1"`.
    /// - The last 2 segments can be written as an IPv4 address in dotted-decimal notation,
    ///   for example `"::ffff:192.0.2.1"`.
    ///
    /// Brackets (`"[::1]"`), interface scopes (`"fe80::1%en0"`) and prefix lengths (`"::1/128"`)
    /// are not part of an address and are rejected.
    public init?(_ description: String) {
        let segments: [UInt16]
        if let compression = description.firstRange(of: "::") {
            // An IPv4 suffix can only come at the very end, so never before the `::`.
            guard
                let head = Self.parseSegments(description[..<compression.lowerBound], allowsIPv4Suffix: false),
                let tail = Self.parseSegments(description[compression.upperBound...], allowsIPv4Suffix: true),
                // `::` stands for at least one zero segment.
                head.count + tail.count <= 7
            else {
                return nil
            }
            segments = head + [UInt16](repeating: 0, count: 8 - head.count - tail.count) + tail
        } else {
            guard
                let all = Self.parseSegments(description[...], allowsIPv4Suffix: true),
                all.count == 8
            else {
                return nil
            }
            segments = all
        }

        self.init(
            segments[0],
            segments[1],
            segments[2],
            segments[3],
            segments[4],
            segments[5],
            segments[6],
            segments[7]
        )
    }

    /// Parses `:`-separated segments, such as either side of a `::`.
    /// Returns `nil` if any segment is invalid, including empty segments from stray `:`.
    ///
    /// If `allowsIPv4Suffix` is true, the last segment can be an IPv4 address, which counts as 2 segments.
    private static func parseSegments(_ text: Substring, allowsIPv4Suffix: Bool) -> [UInt16]? {
        guard !text.isEmpty else {
            return []
        }

        let groups = text.split(separator: ":", omittingEmptySubsequences: false)
        var segments: [UInt16] = []
        for (index, group) in groups.enumerated() {
            if allowsIPv4Suffix, index == groups.count - 1, group.contains(".") {
                guard let ipv4 = IPv4Address(String(group)) else {
                    return nil
                }
                segments.append(UInt16(ipv4[byte: 0]) << 8 | UInt16(ipv4[byte: 1]))
                segments.append(UInt16(ipv4[byte: 2]) << 8 | UInt16(ipv4[byte: 3]))
            } else {
                guard let segment = Self.parseHexSegment(group) else {
                    return nil
                }
                segments.append(segment)
            }
        }
        return segments
    }

    /// Parses 1 to 4 hexadecimal digits, uppercase or lowercase, into a segment.
    private static func parseHexSegment(_ text: Substring) -> UInt16? {
        let utf8 = text.utf8
        guard utf8.count >= 1, utf8.count <= 4 else {
            return nil
        }

        var value: UInt16 = 0
        for byte in utf8 {
            let digit: UInt8
            switch byte {
            case UInt8(ascii: "0")...UInt8(ascii: "9"):
                digit = byte - UInt8(ascii: "0")
            case UInt8(ascii: "a")...UInt8(ascii: "f"):
                digit = byte - UInt8(ascii: "a") + 10
            case UInt8(ascii: "A")...UInt8(ascii: "F"):
                digit = byte - UInt8(ascii: "A") + 10
            default:
                return nil
            }
            value = value << 4 | UInt16(digit)
        }
        return value
    }

    /// The 16-bit segment at `index`, most significant segment first. `index` must be in `0..<8`.
    private func segment(at index: Int) -> UInt16 {
        UInt16(self.bytes[2 * index]) << 8 | UInt16(self.bytes[2 * index + 1])
    }

    /// Whether this is an IPv4-mapped address, in `::ffff:0:0/96` as defined in
    /// [IETF RFC 4291 Section 2.5.5.2](https://datatracker.ietf.org/doc/html/rfc4291#section-2.5.5.2).
    private var isIPv4Mapped: Bool {
        for index in 0..<10 where self.bytes[index] != 0 {
            return false
        }
        return self.bytes[10] == 0xFF && self.bytes[11] == 0xFF
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension IPv6Address: Hashable {
    public static func == (lhs: IPv6Address, rhs: IPv6Address) -> Bool {
        for index in lhs.bytes.indices where lhs.bytes[index] != rhs.bytes[index] {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        for index in self.bytes.indices {
            hasher.combine(self.bytes[index])
        }
    }
}
