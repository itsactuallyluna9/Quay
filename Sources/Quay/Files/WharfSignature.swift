import Foundation

public struct SignatureHeader: FileHeader {
    typealias PBMessage = PBSignatureHeader

    public var compression: CompressionSettings
    
    public init(compression: CompressionSettings) {
        self.compression = compression
    }
    
    init(protobuf: PBSignatureHeader) throws {
        self.compression = try .init(protobuf: protobuf.compression)
    }

    func protobuf() -> PBSignatureHeader {
        var header = PBSignatureHeader()
        header.compression = compression.protobuf()
        return header
    }
}

/// A `WharfSignature` contains a container and a series of hashes corresponding to the container's files.
public struct WharfSignature: WharfFile {
    internal var magic: Magic { .signature }

    public var header: SignatureHeader
    public private(set) var container: QuayContainer
    public private(set) var blockHashes: [BlockHash]
    
    public init(from data: Data) throws {
        let headerResults = try parseHeader(data: data, headerType: SignatureHeader.self, expectedMagic: .signature)
        self.header = headerResults.header
        // Step 4: parse body
        // Body consists of a Container, and then a bunch of BlockHash messages.
        let messages = parseBody(data: headerResults.body)
        guard messages.count > 0 else {
            throw Quay.createError(.unknown, description: "no messages found in body", failureReason: "no messages found in body")
        }
        self.container = try QuayContainer(protobuf: messages.first!)
        self.blockHashes = try messages.dropFirst().map { try BlockHash(protobuf: $0) }
    }

    init(header: SignatureHeader, container: QuayContainer, blockHashes: [BlockHash]) {
        self.header = header
        self.container = container
        self.blockHashes = blockHashes
    }

    func encodeBody() -> [any ProtobufAlias] {
        [container as any ProtobufAlias] + blockHashes as [any ProtobufAlias]
    }

    func encodeHeader() -> any FileHeader {
        header
    }
}


