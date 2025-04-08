import Foundation

public struct BlockHash: ProtobufAlias, Equatable, Hashable {
    typealias PBMessage = PBBlockHash

    public private(set) var weakHash: UInt32
    public private(set) var strongHash: Data

    package var fileIndex: Int?
    package var blockIndex: Int?
    package var shortSize: Int?

    init(protobuf: PBBlockHash) {
        self.strongHash = protobuf.strongHash
        self.weakHash = protobuf.weakHash
    }

    init(block: Data) {
        self.weakHash = WeakRollingHash(block: block).hash
        self.strongHash = MD5Hash.immediateHash(of: block)
    }

    init(weakHash: UInt32, strongHash: Data) {
        self.weakHash = weakHash
        self.strongHash = strongHash
    }

    public static func generateHashes(for src: URL) throws -> [BlockHash] {
        // Scan 64kB blocks, and generate hashes for each block.
        let blockSize = 64 * 1024 // 64kB
        var hashes: [BlockHash] = []

        let fileData = try Data(contentsOf: src)
        var position = 0

        let progress = Progress(totalUnitCount: Int64(fileData.count))

        while position < fileData.count {
            let end = min(position + blockSize, fileData.count)
            let block = fileData[position..<end]
            hashes.append(BlockHash.init(block: block))
            position += blockSize
            progress.completedUnitCount = Int64(position)
        }

        progress.completedUnitCount = Int64(fileData.count)

        return hashes
    }

    mutating func anchor(fileIndex: Int, blockIndex: Int, shortSize: Int) {
        self.fileIndex = fileIndex
        self.blockIndex = blockIndex
        self.shortSize = shortSize
    }

    package var isAnchored: Bool {
        return fileIndex != nil && blockIndex != nil && shortSize != nil
    }

    func protobuf() -> PBBlockHash {
        var hash = PBBlockHash()
        hash.weakHash = weakHash
        hash.strongHash = strongHash
        return hash
    }
    
    /// Computes the number of small blocks a file is made up of.
    static func computeNumBlocks(_ fileSize: Int) -> Int {
        return (fileSize + BlockSize - 1) / BlockSize
    }
    
    /// Computes the size of one of the file's blocks.
    static func computeBlockSize(fileSize: Int, blockIdx: Int) -> Int {
        if BlockSize * (blockIdx+1) > fileSize {
            return fileSize % BlockSize
        }
        return BlockSize
    }
    
    public static func == (lhs: BlockHash, rhs: BlockHash) -> Bool {
        return lhs.weakHash == rhs.weakHash && lhs.strongHash == rhs.strongHash
    }
}
