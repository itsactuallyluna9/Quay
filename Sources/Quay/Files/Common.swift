import Foundation
import SwiftProtobuf
import SwiftBrotli

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
            let result = Brotli().compress(bodyData, quality: header.compression.quality)
            switch result {
            case .success(let compressedData):
                finalData.append(compressedData)
            case .failure(let error):
                throw Quay.createError(.compressionFailed, description: "compression failed", failureReason: error.localizedDescription)
            }
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

func parseHeader<T: FileHeader>(data: Data, headerType: T.Type, expectedMagic: Magic) throws -> (header: T, body: Data) {
    // Step 1: do we have a valid magic number?
        
    try checkMagicNumber(actual: data.readInt32(), expected: expectedMagic)
    
    // Step 2: parse header
    let headerLength = Int(try data.readUVarInt(offset: 4).value)
    let header = try headerType.init(protobuf: data.dropFirst(4+data.readUVarInt(offset: 4).bytesRead).prefix(headerLength))
    
    // Step 3: uncompress based on the header
    let body: Data
    switch header.compression.algorithm {
    case .none:
        // noop
        body = data.dropFirst(try 4 + data.readUVarInt(offset: 4).bytesRead + headerLength)
        break
    case .brotli:
        let result = Brotli().decompress(data.dropFirst(5+headerLength))
        switch result {
        case .success(let decompressedData):
            body = decompressedData
        case .failure(let error):
            throw Quay.createError(.decompressionFailed, description: "decompression failed", failureReason: error.localizedDescription)
        }
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
    try! data.write(to: URL(fileURLWithPath: "/tmp/patch.pwr.body"))
    var pos = data.startIndex
    var messages: [Data] = []
    while pos < data.endIndex {
        let len = try! data.readUVarInt(offset: pos)
        let messageLength = Int(len.value)
        pos += len.bytesRead
        // if messageLength == 0 {
        //     continue
        // }
        messages.append(data.dropFirst(pos).prefix(messageLength))
        pos += messageLength
    }
    
    return messages
}
