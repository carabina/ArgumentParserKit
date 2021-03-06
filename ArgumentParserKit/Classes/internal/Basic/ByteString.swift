/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

/// A `ByteString` represents a sequence of bytes.
///
/// This struct provides useful operations for working with buffers of
/// bytes. Conceptually it is just a contiguous array of bytes (UInt8), but it
/// contains methods and default behavor suitable for common operations done
/// using bytes strings.
///
/// This struct *is not* intended to be used for significant mutation of byte
/// strings, we wish to retain the flexibility to micro-optimize the memory
/// allocation of the storage (for example, by inlining the storage for small
/// strings or and by eliminating wasted space in growable arrays). For
/// construction of byte arrays, clients should use the `OutputByteStream` class
/// and then convert to a `ByteString` when complete.
struct ByteString: ExpressibleByArrayLiteral, Hashable {
    /// The buffer contents.
    fileprivate var _bytes: [UInt8]

    /// Create an empty byte string.
    init() {
        _bytes = []
    }

    /// Create a byte string from a byte array literal.
    init(arrayLiteral contents: UInt8...) {
        _bytes = contents
    }

    /// Create a byte string from an array of bytes.
    init(_ contents: [UInt8]) {
        _bytes = contents
    }

    /// Create a byte string from an byte buffer.
    init<S: Sequence> (_ contents: S) where S.Iterator.Element == UInt8 {
        _bytes = [UInt8](contents)
    }

    /// Create a byte string from the UTF8 encoding of a string.
    init(encodingAsUTF8 string: String) {
        _bytes = [UInt8](string.utf8)
    }

    /// Access the byte string contents as an array.
    var contents: [UInt8] {
        return _bytes
    }

    /// Return the byte string size.
    var count: Int {
        return _bytes.count
    }

    /// Return the string decoded as a UTF8 sequence, if possible.
    var asString: String? {
        // FIXME: This is very inefficient, we need a way to pass a buffer. It
        // is also wrong if the string contains embedded '\0' characters.
        let tmp = _bytes + [UInt8(0)]
        return tmp.withUnsafeBufferPointer { ptr in
            return String(validatingUTF8: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
        }
    }

    /// Return the string decoded as a UTF8 sequence, substituting replacement
    /// characters for ill-formed UTF8 sequences.
    var asReadableString: String {
        // FIXME: This is very inefficient, we need a way to pass a buffer. It
        // is also wrong if the string contains embedded '\0' characters.
        let tmp = _bytes + [UInt8(0)]
        return tmp.withUnsafeBufferPointer { ptr in
            return String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
        }
    }
}

/// Conform to CustomStringConvertible.
extension ByteString: CustomStringConvertible {
    var description: String {
        // For now, default to the "readable string" representation.
        return "<ByteString:\"\(asReadableString)\">"
    }
}

#if !swift(>=4.2)
extension ByteString {
    var hashValue: Int {
        var result = contents.count
        for byte in contents {
            result = result &* 31 &+ Int(byte)
        }
        return result
    }
}
#endif

#if !swift(>=4.1)
extension ByteString {
    static func == (lhs: ByteString, rhs: ByteString) -> Bool {
        return lhs.contents == rhs.contents
    }
}
#endif

/// ByteStreamable conformance for a ByteString.
extension ByteString: ByteStreamable {
    func write(to stream: OutputByteStream) {
        stream.write(_bytes)
    }
}

/// StringLiteralConvertable conformance for a ByteString.
extension ByteString: ExpressibleByStringLiteral {
    typealias UnicodeScalarLiteralType = StringLiteralType
    typealias ExtendedGraphemeClusterLiteralType = StringLiteralType

    init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        _bytes = [UInt8](value.utf8)
    }
    init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        _bytes = [UInt8](value.utf8)
    }
    init(stringLiteral value: StringLiteralType) {
        _bytes = [UInt8](value.utf8)
    }
}
