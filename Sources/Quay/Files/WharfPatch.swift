import Foundation

public struct SyncOp: ProtobufAlias {
    typealias PBMessage = PBSyncOp

    public enum SyncOpType: Int, CaseIterable, Equatable, Sendable {
        case blockRange = 0
        case data = 1
        case heyYouDidIt = 2049

        static func fromProtobuf(_ protobuf: PBSyncOp.PBType) throws -> SyncOpType {
            guard let algo = SyncOpType.init(rawValue: protobuf.rawValue) else {
                throw Quay.createError(.invalidHeader, description: "Invalid compression algorithm", failureReason: "Unknown compression algorithm with value \(protobuf.rawValue)")
            }
            return algo
        }
    }

    public package(set) var type: SyncOpType
    public package(set) var fileIndex: Int?
    public package(set) var blockIndex: Int?
    public package(set) var blockSpan: Int?
    public package(set) var data: Data?

    init(protobuf: PBSyncOp) throws {
        self.type = try .fromProtobuf(protobuf.type)
        self.fileIndex = Int(protobuf.fileIndex)
        self.blockIndex = Int(protobuf.blockIndex)
        self.blockSpan = Int(protobuf.blockSpan)
        self.data = protobuf.data
    }

    init(type: SyncOpType, fileIndex: Int, blockIndex: Int, blockSpan: Int, data: Data) {
        self.type = type
        self.fileIndex = fileIndex
        self.blockIndex = blockIndex
        self.blockSpan = blockSpan
        self.data = data
    }

    func protobuf() -> PBSyncOp {
        var op = PBSyncOp()
        op.type = PBSyncOp.PBType(rawValue: type.rawValue)!
        op.fileIndex = Int64(fileIndex ?? 0)
        op.blockIndex = Int64(blockIndex ?? 0)
        op.blockSpan = Int64(blockSpan ?? 0)
        op.data = data ?? Data()
        return op
    }
}

public struct PatchHeader: FileHeader {
    typealias PBMessage = PBPatchHeader

    public var compression: CompressionSettings
    
    public init(compression: CompressionSettings) {
        self.compression = compression
    }
    
    init(protobuf: PBPatchHeader) throws {
        self.compression = try .init(protobuf: protobuf.compression)
    }
    
    func protobuf() -> PBPatchHeader {
        var header = PBPatchHeader()
        header.compression = compression.protobuf()
        return header
    }
}

/// A `WharfPatch` contains all of the information needed to apply an upgrade from `old` to `new`.
public struct WharfPatch: WharfFile {
    var magic: Magic { .patch }

    public private(set) var header: PatchHeader
    public private(set) var targetContainer: QuayContainer
    public private(set) var sourceContainer: QuayContainer
    public private(set) var syncOps: [SyncOp]
    
    public init(from data: Data) throws {
        let headerResults = try parseHeader(data: data, headerType: PatchHeader.self, expectedMagic: .patch)
        self.header = headerResults.header
        // Step 4: parse body
        // Body consists of two Containers, and then a bunch of SyncOp messages.
        let messages = parseBody(data: headerResults.body)
        guard messages.count > 0 else {
            throw Quay.createError(.unknown, description: "no messages found in body", failureReason: "no messages found in body")
        }
        self.targetContainer = try QuayContainer(protobuf: messages[0])
        self.sourceContainer = try QuayContainer(protobuf: messages[1])
        self.syncOps = try messages.dropFirst(2).map { try SyncOp(protobuf: $0) }
    }

    public init(target: WharfSignature, source: URL) throws {
        let owedMax = 4 * 1024 * 1024 // 4MB

        let library = constructBlockLibrary(hashes: target.blockHashes)
        self.header = .init(compression: .transportDefault)
        self.targetContainer = target.container
        self.sourceContainer = try QuayContainer(folder: source)
        self.syncOps = []
        var weakHashDigest = WeakRollingHash()

        for file in sourceContainer.iterFiles(source) {
            weakHashDigest.reset()
            var owedTail = 0
            var owedHead = 0
            var tail = 0
            var head = 64 * 1024

            let fileData = try Data(contentsOf: file)
            let perferredFileIndex = target.container.files.firstIndex { $0.name == file.path } ?? -1

            // alright, lets actually do this!
            // process is simple:
            // scan through the file, having a window of 64KB between head and tail
            // keep updating the rolling hash
            // if ever the rolling hash is in our library, check the strong hash
            // if so, we have a match!
            // if not, keep going.
            
            // anything not between head and tail that we haven't "saved" yet is owed
            // if that ever gets above 4MB, we need to write it out.
            // if we find a match, we need to write out the owed data, then we can do the thing

            while head < fileData.count {
                let byte = fileData[head]
                let weakHash = weakHashDigest.update(withByte: byte)
                if head - tail < 64 * 1024 {
                    // we haven't filled the window yet...
                    head += 1
                    continue
                }
                
                // did we get a hit?
                if let candidates = library[weakHash] {
                    // weak hash hit!
                    // compute and check strong hash
                    // md5 the 64KB window
                    let strongHash = fileData.subdata(in: tail..<head).md5()
                    
                    // check if we have a match
                    if let match = candidates.first(where: { $0.strongHash == strongHash }) {
                        // we have a match!
                        // write out the owed data
                        if owedTail < tail {
                            let span = owedTail..<tail
                            let owedData = fileData.subdata(in: span)
                            self.syncOps.append(.init(type: .data, fileIndex: -1, blockIndex: 0, blockSpan: 0, data: owedData))
                            owedTail = tail
                        }
                        // write out the match
                        self.syncOps.append(.init(type: .blockRange, fileIndex: -1, blockIndex: head, blockSpan: 64 * 1024, data: Data()))
                        // reset the window
                        tail = head
                        owedHead = head
                        owedTail = head
                        weakHashDigest.reset()
                    } 
                } else {
                    // no hit, keep going
                    head += 1
                }

                // check if we owe anything
                if owedHead - owedTail > owedMax {
                    // write out the owed data
                    let span = owedTail..<owedHead
                    let owedData = fileData.subdata(in: span)
                    self.syncOps.append(.init(type: .data, fileIndex: -1, blockIndex: 0, blockSpan: 0, data: owedData))
                    owedTail = owedHead
                }
            }

            // do one last check...
            owedHead = fileData.count
            if owedHead - owedTail > 0 {
                // write out the owed data
                let span = owedTail..<owedHead
                let owedData = fileData.subdata(in: span)
                self.syncOps.append(.init(type: .data, fileIndex: -1, blockIndex: 0, blockSpan: 0, data: owedData))
            }
        }

        self.syncOps.append(.init(type: .heyYouDidIt, fileIndex: 0, blockIndex: 0, blockSpan: 0, data: Data()))
    }

    func encodeHeader() -> any FileHeader {
        header
    }

    func encodeBody() -> [any ProtobufAlias] {
        [targetContainer as any ProtobufAlias, sourceContainer as any ProtobufAlias] + syncOps as [any ProtobufAlias]
    }
}
