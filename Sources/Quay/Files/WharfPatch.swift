import Foundation

public struct SyncOpHeader: ProtobufAlias {
    typealias PBMessage = PBSyncHeader

    public enum SyncHeaderType: Int, CaseIterable, Equatable, Sendable {
        case rsync = 0
        case bsdiff = 1

        static func fromProtobuf(_ protobuf: PBSyncHeader.PBType) throws -> SyncHeaderType {
            guard let algo = SyncHeaderType.init(rawValue: protobuf.rawValue) else {
                throw Quay.createError(.invalidHeader, description: "Invalid compression algorithm", failureReason: "Unknown compression algorithm with value \(protobuf.rawValue)")
            }
            return algo
        }
    }

    public package(set) var type: SyncHeaderType
    public package(set) var fileIndex: Int

    init(protobuf: PBSyncHeader) throws {
        self.type = try .fromProtobuf(protobuf.type)
        self.fileIndex = Int(protobuf.fileIndex)
    }

    init(type: SyncHeaderType, fileIndex: Int) {
        self.type = type
        self.fileIndex = fileIndex
    }

    func protobuf() -> PBSyncHeader {
        var header = PBSyncHeader()
        header.type = PBSyncHeader.PBType(rawValue: type.rawValue)!
        header.fileIndex = Int64(fileIndex)
        return header
    }
}

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

    init(type: SyncOpType, fileIndex: Int?, blockIndex: Int?, blockSpan: Int?, data: Data?) {
        self.type = type
        self.fileIndex = fileIndex
        self.blockIndex = blockIndex
        self.blockSpan = blockSpan
        self.data = data
    }

    static func initBlockRange(fileIndex: Int, blockIndex: Int, blockSpan: Int) -> SyncOp {
        SyncOp(type: .blockRange, fileIndex: fileIndex, blockIndex: blockIndex, blockSpan: blockSpan, data: nil)
    }

    static func initData(data: Data) -> SyncOp {
        SyncOp(type: .data, fileIndex: nil, blockIndex: nil, blockSpan: nil, data: data)
    }

    static func initHeyYouDidIt() -> SyncOp {
        SyncOp(type: .heyYouDidIt, fileIndex: nil, blockIndex: nil, blockSpan: nil, data: nil)
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
protocol SyncOperation: ProtobufAlias {}
extension SyncOp: SyncOperation {}
extension SyncOpHeader: SyncOperation {}

public struct WharfPatch: WharfFile {
    var magic: Magic { .patch }

    public var header: PatchHeader
    public private(set) var targetContainer: QuayContainer
    public private(set) var sourceContainer: QuayContainer
    private(set) var syncOps: [any SyncOperation]
    
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
        self.syncOps = []

        var nextHeader = true
        for message in messages.dropFirst(2) {
            if nextHeader {
                nextHeader = false
                self.syncOps.append(try SyncOpHeader(protobuf: message))
            } else {
                let parsed = try SyncOp(protobuf: message)
                self.syncOps.append(parsed)
                if parsed.type == .heyYouDidIt {
                    nextHeader = true
                }
            }
        }
    }

    public init(target: WharfSignature, source: URL) throws {
        let owedMax = 4 * 1024 * 1024 // 4MB

        let library = constructBlockLibrary(signature: target)
        self.header = .init(compression: .transportDefault)
        self.targetContainer = target.container
        self.sourceContainer = try QuayContainer(folder: source)
        self.syncOps = []
        var weakHashDigest = WeakRollingHash()

        for (fileIndex, file) in sourceContainer.iterFiles(source).enumerated() {
            weakHashDigest.reset()
            var owedTail = 0
            var owedHead = 0
            var tail = 0
            var head = 64 * 1024

            let fileData = try Data(contentsOf: file)
            let filePath = file.path
            let perferredFileIndex = target.container.files.firstIndex { $0.name == filePath } ?? -1

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

            self.syncOps.append(SyncOpHeader.init(type: .rsync, fileIndex: fileIndex))

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
                    // Sort candidates to prioritize the preferred file index
                    let sortedCandidates = candidates.sorted { (lhs, rhs) in
                        if lhs.fileIndex == perferredFileIndex {
                            return true
                        } else if rhs.fileIndex == perferredFileIndex {
                            return false
                        } else {
                            return lhs.fileIndex! < rhs.fileIndex!
                        }
                    }

                    if let match = sortedCandidates.first(where: { $0.strongHash == strongHash }) {
                        // we have a match!
                        // write out the owed data if we have any
                        if owedTail < tail {
                            let span = owedTail..<tail
                            let owedData = fileData.subdata(in: span)
                            self.syncOps.append(SyncOp.initData(data: owedData))
                            owedTail = tail
                        }
                        // write out the match
                        // if the previous syncOp was a blockRange, we can extend it
                        if var lastOp = syncOps.last as? SyncOp, lastOp.type == .blockRange, lastOp.fileIndex == match.fileIndex, (lastOp.blockIndex! + lastOp.blockSpan!) == match.blockIndex {
                            lastOp.blockSpan! += 1
                        } else {
                            syncOps.append(SyncOp.initBlockRange(fileIndex: match.fileIndex!, blockIndex: match.blockIndex!, blockSpan: 1))
                        }
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
                    self.syncOps.append(SyncOp.initData(data: owedData))
                    owedTail = owedHead
                }
            }

            // do one last check...
            owedHead = fileData.count
            if owedHead - owedTail > 0 {
                // write out the owed data
                // TODO: check if we can extend the last blockRange
                let span = owedTail..<owedHead
                let owedData = fileData.subdata(in: span)
                self.syncOps.append(SyncOp.initData(data: owedData))
            }
            self.syncOps.append(SyncOp.initHeyYouDidIt())
        }
    }

    func encodeHeader() -> any FileHeader {
        header
    }

    func encodeBody() -> [any ProtobufAlias] {
        [targetContainer as any ProtobufAlias, sourceContainer as any ProtobufAlias] + syncOps as [any ProtobufAlias]
    }
}
