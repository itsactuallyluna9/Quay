import Foundation
import SwiftProtobuf

protocol ProtobufAlias: Sendable {
    associatedtype PBMessage: SwiftProtobuf.Message

    init(protobuf: PBMessage) throws
    init(protobuf: Data) throws
    func protobuf() -> PBMessage
}

extension ProtobufAlias {
    init(protobuf: Data) throws {
        let header = try PBMessage(serializedBytes: protobuf)
        try self.init(protobuf: header)
    }
}

protocol FileHeader: ProtobufAlias {
    var compression: CompressionSettings { get }
}

protocol WharfFile {
    var magic: Magic { get }

    init(from data: Data) throws
    init(file: URL) throws

    func encodeHeader() -> any FileHeader
    func encodeBody() -> [any ProtobufAlias]

    func encode() throws -> Data
    func encode(to: URL) throws
}

extension WharfFile {
    public init(file: URL) throws {
        let data = try Data(contentsOf: file)
        try self.init(from: data)
    }

    public func encode(to file: URL) throws {
        let data = try self.encode()
        try data.write(to: file)
    }

    public func encode() throws -> Data {
        let header = encodeHeader()
        let body = try encodeBody().map { try $0.protobuf().serializedData() }
        var bodyData = Data()
        var finalData = Data()
        finalData.append(withUnsafeBytes(of: magic.rawValue) { Data($0) })

        // serialize header
        let headerData = try header.protobuf().serializedData()
        finalData.append(UInt8(headerData.count))
        finalData.append(headerData)

        for msg in body {
            bodyData.append(UInt8(msg.count))
            bodyData.append(msg)
        }

        // compress body
        switch header.compression.algorithm {
        case .none:
            finalData.append(bodyData)
        case .brotli:
            throw Quay.createError(.unimplemented, description: "brotli compression is not yet supported", failureReason: "brotli compression is not yet supported")
        case .gzip:
            throw Quay.createError(.unimplemented, description: "gzip compression is not yet supported", failureReason: "gzip compression is not yet supported")
        case .zstd:
            throw Quay.createError(.unimplemented, description: "zstd compression is not yet supported", failureReason: "zstd compression is not yet supported")
        }

        return finalData
    }
}

private func checkMagicNumber(actual: Int32, expected: Magic) throws {
    guard actual == expected.rawValue else {
        throw Quay.createError(.invalidMagicNumber, description: "invalid magic number!", failureReason: "invalid magic number!")
    }
}

func parseHeader(data: Data, expectedMagic: Magic) throws -> (header: SignatureHeader, body: Data) {
    // Step 1: do we have a valid magic number?
        
    try checkMagicNumber(actual: data.readInt32(), expected: Magic.signature)
    
    // Step 2: parse header
    let headerLength = Int(data.readUInt8(at: 4))
    let header = try SignatureHeader(protobuf: data.dropFirst(5).prefix(headerLength))
    
    // Step 3: uncompress based on the header
    let body: Data
    switch header.compression.algorithm {
    case .none:
        // noop
        body = data.dropFirst(5+headerLength)
        break
    case .brotli:
        throw Quay.createError(.unimplemented, description: "brotli compression is not yet supported", failureReason: "brotli compression is not yet supported")
    case .gzip:
        throw Quay.createError(.unimplemented, description: "gzip compression is not yet supported", failureReason: "gzip compression is not yet supported")
    case .zstd:
        throw Quay.createError(.unimplemented, description: "zstd compression is not yet supported", failureReason: "zstd compression is not yet supported")
    }

    return (header, body)
}

func parseBody(data: Data) -> [Data] {
    // Step 4: parse body
    
    // always message length, then message
    // repeat until end of data
    var pos = data.startIndex
    var messages: [Data] = []
    while pos < data.endIndex {
        let messageLength = Int(data.readUInt8(at: pos))
        pos += 1
        messages.append(data.dropFirst(pos).prefix(messageLength))
        pos += messageLength
    }
    
    return messages
}
