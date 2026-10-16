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

/// An IPv4 address.
///
/// IPv4 addresses are 32-bit values, made of 4 bytes in network byte order (most significant byte first),
/// as defined in [IETF RFC 791].
///
/// [IETF RFC 791]: https://datatracker.ietf.org/doc/html/rfc791
@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
public struct IPv4Address: Sendable {
    /// The 4 bytes of the address, in network byte order.
    /// For example `192.168.1.1` is `[192, 168, 1, 1]`.
    private let bytes: [4 of UInt8]

    /// Creates a new address from its 4 bytes, in network byte order.
    /// For example `IPv4Address(192, 168, 1, 1)` is `192.168.1.1`.
    public init(_ first: UInt8, _ second: UInt8, _ third: UInt8, _ fourth: UInt8) {
        self.bytes = [first, second, third, fourth]
    }

    /// Creates a new address from its 4 bytes, in network byte order.
    /// Returns `nil` unless `bytes` contains exactly 4 bytes.
    public init?(bytes: Span<UInt8>) {
        guard bytes.count == 4 else {
            return nil
        }
        self.bytes = .init { index in bytes[index] }
    }

    /// Creates a new address from its numeric value, in host byte order.
    /// For example `IPv4Address(numericValue: 0x7F00_0001)` is `127.0.0.1`.
    public init(numericValue: UInt32) {
        self.init(
            UInt8(truncatingIfNeeded: numericValue >> 24),
            UInt8(truncatingIfNeeded: numericValue >> 16),
            UInt8(truncatingIfNeeded: numericValue >> 8),
            UInt8(truncatingIfNeeded: numericValue)
        )
    }

    /// Creates a new address from a 32-bit integer in network byte order.
    ///
    /// In memory, the integer holds the address's 4 bytes in order, so its numeric value depends
    /// on the platform's byte order. To create an address from a number like `0x7F00_0001`, use
    /// `init(numericValue:)` instead.
    public init(networkOrder: UInt32) {
        self.init(numericValue: UInt32(bigEndian: networkOrder))
    }

    /// The byte at `index`, in network byte order. `index` must be in `0..<4`.
    /// For example the byte at index `0` of `192.168.1.1` is `192`.
    public subscript(byte index: Int) -> UInt8 {
        self.bytes[index]
    }

    /// The numeric value of the address.
    /// For example the numeric value of `127.0.0.1` is `0x7F00_0001`.
    public var numericValue: UInt32 {
        self.bytes.span.bytes
            .unsafeLoadUnaligned(as: UInt32.self)
            .bigEndian
    }

    /// Calls `body` with a `Span` of the address's 4 bytes, in network byte order.
    public func withBytes<Result>(_ body: (Span<UInt8>) throws -> Result) rethrows -> Result {
        try body(self.bytes.span)
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension IPv4Address {
    /// The loopback address, `127.0.0.1`.
    public static let loopback = IPv4Address(127, 0, 0, 1)

    /// The unspecified address, `0.0.0.0`.
    public static let any = IPv4Address(0, 0, 0, 0)

    /// The limited broadcast address, `255.255.255.255`.
    public static let broadcast = IPv4Address(255, 255, 255, 255)
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension IPv4Address: LosslessStringConvertible {
    /// The textual representation of the address, in dotted-decimal notation.
    /// For example `"192.168.1.1"`.
    public var description: String {
        "\(self.bytes[0]).\(self.bytes[1]).\(self.bytes[2]).\(self.bytes[3])"
    }

    /// Creates a new address from its textual representation, in dotted-decimal notation.
    /// That is, exactly 4 decimal numbers from 0 to 255 separated by `.`, for example `"192.168.1.1"`.
    ///
    /// Leading zeros such as in `"192.168.01.1"` are rejected, because some parsers read them as octal.
    public init?(_ description: String) {
        var parsed: [4 of UInt8] = .init(repeating: 0)
        var byteIndex = 0
        var value = 0
        var digitCount = 0

        for byte in description.utf8 {
            if byte == UInt8(ascii: ".") {
                guard digitCount > 0, byteIndex < 3 else {
                    return nil
                }
                parsed[byteIndex] = UInt8(value)
                byteIndex += 1
                value = 0
                digitCount = 0
            } else if byte >= UInt8(ascii: "0"), byte <= UInt8(ascii: "9") {
                // A digit after a leading `0` means the number has a leading zero.
                guard digitCount == 0 || value != 0 else {
                    return nil
                }
                value = value * 10 + Int(byte - UInt8(ascii: "0"))
                digitCount += 1
                guard value <= 255 else {
                    return nil
                }
            } else {
                return nil
            }
        }

        guard byteIndex == 3, digitCount > 0 else {
            return nil
        }
        parsed[3] = UInt8(value)
        self.bytes = parsed
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension IPv4Address: Hashable {
    public static func == (lhs: IPv4Address, rhs: IPv4Address) -> Bool {
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
