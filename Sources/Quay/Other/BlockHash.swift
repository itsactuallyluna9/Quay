import Foundation
import CryptoSwift

package struct WeakRollingHash {
    private let _M: UInt32 = 1 << 16
    private var beta1: UInt32 = 0
    private var beta2: UInt32 = 0

    private static let bufferSize = 64 * 1024
    private var buffer: [UInt8]
    private var head = 0
    private var tail = 0

    init() {
        buffer = Array(repeating: 0, count: WeakRollingHash.bufferSize)
    }

    init(block: [UInt8]) {
        buffer = Array(repeating: 0, count: WeakRollingHash.bufferSize)
        update(withBytes: block)
    }

    mutating func update(withBytes: Array<UInt8>) {
        for byte in withBytes {
            _ = update(withByte: byte)
        }
    }

    mutating func update(withByte byte: UInt8) -> UInt32 {
        // Store in buffer
        buffer[head % buffer.count] = byte

        let aPush = UInt32(byte)
        let aPop = head - tail >= buffer.count ? UInt32(buffer[tail % buffer.count]) : 0

        beta1 = (beta1 - aPop + aPush) % _M
        beta2 = (beta2 - ((UInt32(head - tail) * aPop) % _M) + beta1) % _M

        head += 1
        if head - tail > buffer.count {
            tail += 1
        }

        return self.hash
    }

    mutating func reset() {
        beta1 = 0
        beta2 = 0
        head = 0
        tail = 0
    }

    var hash: UInt32 {
        return beta1 + _M * beta2
    }
}

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
        self.weakHash = WeakRollingHash(block: block.bytes).hash
        self.strongHash = block.md5()
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
}
