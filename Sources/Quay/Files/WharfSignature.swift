import Foundation

/// A `WharfSignature` contains a container and a series of hashes corresponding to the container's files.
public struct WharfSignature: WharfFile {
    public struct Header: FileHeader {
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
    
    internal var magic: Magic { .signature }

    public var header: Header
    public private(set) var container: QuayContainer
    public package(set) var blockHashes: [BlockHash]
    
    public init(from data: Data) throws {
        let headerResults = try parseHeader(data: data, headerType: Header.self, expectedMagic: .signature)
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

    public init(from url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(from: data)
    }

    init(header: Header, container: QuayContainer, blockHashes: [BlockHash]) {
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

public extension WharfSignature {
    func encode() throws -> Data {
        return try encodeWharfFile(self)
    }
    
    func encode(to url: URL) throws {
        let data = try encode()
        try data.write(to: url)
    }
}


