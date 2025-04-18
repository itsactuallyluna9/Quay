import Foundation

// MARK: Legacy
// We're still keeping this around until we refactor ProtobufAlias.
// This shouldn't be touched, though.

struct SyncOpHeader: ProtobufAlias {
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

    @available(*, deprecated, renamed: "SyncOperation.from(protobuf:)", message: "code cleanup")
    init(protobuf: PBSyncHeader) throws {
        self.type = try .fromProtobuf(protobuf.type)
        self.fileIndex = Int(protobuf.fileIndex)
    }

    init(type: SyncHeaderType, fileIndex: Int) {
        self.type = type
        self.fileIndex = fileIndex
    }

    @available(*, deprecated, renamed: "SyncOperation.protobuf()", message: "code cleanup")
    func protobuf() -> PBSyncHeader {
        var header = PBSyncHeader()
        header.type = PBSyncHeader.PBType(rawValue: type.rawValue)!
        header.fileIndex = Int64(fileIndex)
        return header
    }
}

struct SyncOp: ProtobufAlias {
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

    @available(*, deprecated, renamed: "SyncOperation.from(protobuf:)", message: "code cleanup")
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

    @available(*, deprecated, renamed: "SyncOperation.protobuf()", message: "code cleanup")
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

// MARK: Rewritten

public enum SyncOperation {
    public enum Algorithm: Int {
        case rsync = 0
        case bsdiff = 1
        
        var legacy: SyncOpHeader.SyncHeaderType {
            switch self {
            case .rsync: return .rsync
            case .bsdiff: return .bsdiff
            }
        }
    }
    
    case startFile(algorithm: Algorithm, fileIndex: Int)
    case blockRange(sourceFileIndex: Int, blockIndex: Int, blockSpan: Int)
    case data(data: Data)
    case heyYouDidIt // keeping the name since it's cool :>
    
    static func fromProtobuf(_ protobuf: PBSyncOp) throws -> SyncOperation {
        switch protobuf.type {
        case .blockRange:
            return .blockRange(sourceFileIndex: Int(protobuf.fileIndex), blockIndex: Int(protobuf.blockIndex), blockSpan: Int(protobuf.blockSpan))
        case .data:
            return .data(data: protobuf.data)
        case .heyYouDidIt:
            return .heyYouDidIt
        case .UNRECOGNIZED(_):
            throw Quay.createError(.decodeFailed, description: "Unrecognized Sync Operation", failureReason: nil)
        }
    }
    
    func protobuf() -> any ProtobufAlias {
        switch self {
        case .startFile(let algorithm, let fileIndex):
            return SyncOpHeader(type: algorithm.legacy, fileIndex: fileIndex)
        case .blockRange(let sourceFileIndex, let blockIndex, let blockSpan):
            return SyncOp(type: .blockRange, fileIndex: sourceFileIndex, blockIndex: blockIndex, blockSpan: blockSpan, data: nil)
        case .data(let data):
            return SyncOp(type: .data, fileIndex: nil, blockIndex: nil, blockSpan: nil, data: data)
        case .heyYouDidIt:
            return SyncOp(type: .heyYouDidIt, fileIndex: nil, blockIndex: nil, blockSpan: nil, data: nil)
        }
    }
}

/// A `WharfPatch` contains all of the information needed to apply an upgrade from `old` to `new`.
public struct WharfPatch: WharfFile {
    var magic: Magic { .patch }
    
    public struct Header: FileHeader {
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

    public var header: Header
    public private(set) var targetContainer: QuayContainer
    public private(set) var sourceContainer: QuayContainer
    private(set) var syncOps: [SyncOperation]
    
    public init(from data: Data) throws {
        let headerResults = try parseHeader(data: data, headerType: Header.self, expectedMagic: .patch)
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
//                self.syncOps.append(try SyncOpHeader(protobuf: message))
            } else {
                let parsed = try SyncOp(protobuf: message)
//                self.syncOps.append(parsed)
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

        let progress = Progress(totalUnitCount: Int64(sourceContainer.files.count))

        for (fileIndex, file) in sourceContainer.iterFiles(source).enumerated() {
            weakHashDigest.reset()
            var owedTail = 0
            var owedHead = 0
            var tail = 0
            var head = 0

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

            self.syncOps.append(.startFile(algorithm: .rsync, fileIndex: fileIndex))

            while head < fileData.count {
                let byte = fileData[head]
                let weakHash = weakHashDigest.update(withByte: byte)
                
                // did we get a hit?
                if let candidates = library[weakHash] {
                    // weak hash hit!
                    // compute and check strong hash
                    // md5 the 64KB window
                    let strongHash = MD5Hash.immediateHash(of: fileData.subdata(in: tail..<head))
                    
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
                            self.syncOps.append(.data(data: owedData))
                            owedTail = tail
                        }
                        // write out the match
                        // if the previous syncOp was a blockRange, we can extend it
                        if let lastOp = syncOps.last, case .blockRange(let sourceFileIndex, let blockIndex, var blockSpan) = lastOp, sourceFileIndex == match.fileIndex, (blockIndex + blockSpan) == match.blockIndex {
                            blockSpan += 1
                        } else {
                            syncOps.append(.blockRange(sourceFileIndex: match.fileIndex!, blockIndex: match.blockIndex!, blockSpan: 1))
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
                    self.syncOps.append(.data(data: owedData))
                    owedTail = owedHead
                }
            }

            // do one last check...
            owedHead = fileData.count
            if owedHead - owedTail > 0 {
                // write out the owed data                
                let span = owedTail..<owedHead
                let remainingData = fileData.subdata(in: span)
                
                // check if this remaining data matches a block in the target
                let remainingWeakHash = WeakRollingHash.immediateHash(of: remainingData)
                if let candidates = library[remainingWeakHash] {
                    let remainingStrongHash = MD5Hash.immediateHash(of: remainingData)
                    
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
                    
                    if let match = sortedCandidates.first(where: { $0.strongHash == remainingStrongHash }) {
                        // found a match :>

                        if let lastOp = syncOps.last, case .blockRange(let sourceFileIndex, let blockIndex, var blockSpan) = lastOp, sourceFileIndex == match.fileIndex, (blockIndex + blockSpan) == match.blockIndex {
                            blockSpan += 1
                        } else {
                            // new block range
                            syncOps.append(.blockRange(sourceFileIndex: match.fileIndex!, blockIndex: match.blockIndex!, blockSpan: 1))
                        }
                    } else {
                        // no match found, just write the data
                        self.syncOps.append(.data(data: remainingData))
                    }
                } else {
                    // no match found, just write the data
                    self.syncOps.append(.data(data: remainingData))
                }
            }

            self.syncOps.append(.heyYouDidIt)
            progress.completedUnitCount = Int64(fileIndex)
        }
    }

    func encodeHeader() -> any FileHeader {
        header
    }

    func encodeBody() -> [any ProtobufAlias] {
        [targetContainer as any ProtobufAlias, sourceContainer as any ProtobufAlias] + syncOps.map( { $0.protobuf() }) as [any ProtobufAlias]
    }
}
