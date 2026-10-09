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

/// An IP address, either IPv4 or IPv6.
@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
public enum IPAddress: Sendable, Hashable {
    case v4(IPv4Address)
    case v6(IPv6Address)

    /// The IPv4 address, or `nil` if this is an IPv6 address.
    public var ipv4: IPv4Address? {
        switch self {
        case .v4(let address):
            return address
        case .v6:
            return nil
        }
    }

    /// The IPv6 address, or `nil` if this is an IPv4 address.
    public var ipv6: IPv6Address? {
        switch self {
        case .v4:
            return nil
        case .v6(let address):
            return address
        }
    }
}

@available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
extension IPAddress: LosslessStringConvertible {
    /// The textual representation of the address.
    public var description: String {
        switch self {
        case .v4(let address):
            return address.description
        case .v6(let address):
            return address.description
        }
    }

    /// Creates a new address from its textual representation, either IPv4 or IPv6.
    /// For example `"192.168.1.1"` or `"2001:db8::1"`.
    public init?(_ description: String) {
        if let address = IPv4Address(description) {
            self = .v4(address)
        } else if let address = IPv6Address(description) {
            self = .v6(address)
        } else {
            return nil
        }
    }
}
