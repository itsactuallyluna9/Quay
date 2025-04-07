import Testing
import Foundation
@testable import Quay

@Test func testComputeNumBlocks() async throws {
    #expect(0 == BlockHash.computeNumBlocks(0))
    #expect(1 == BlockHash.computeNumBlocks(1))
    #expect(1 == BlockHash.computeNumBlocks(BlockSize - 1))
    #expect(1 == BlockHash.computeNumBlocks(BlockSize))
    #expect(2 == BlockHash.computeNumBlocks(BlockSize+1))
    #expect(2 == BlockHash.computeNumBlocks(BlockSize*2 - 1))
    #expect(3 == BlockHash.computeNumBlocks(BlockSize*2+1))
}

@Test func testComputeBlockSize() async throws {
    #expect(BlockSize - 1 == BlockHash.computeBlockSize(fileSize: BlockSize - 1, blockIdx: 0))
    
    #expect(BlockSize == BlockHash.computeBlockSize(fileSize: BlockSize, blockIdx: 0))
    
    #expect(BlockSize == BlockHash.computeBlockSize(fileSize: BlockSize + 1, blockIdx: 0))
    #expect(1 == BlockHash.computeBlockSize(fileSize: BlockSize + 1, blockIdx: 1))
    
    #expect(BlockSize == BlockHash.computeBlockSize(fileSize: BlockSize*2 + 1, blockIdx: 0))
    #expect(BlockSize == BlockHash.computeBlockSize(fileSize: BlockSize*2 + 1, blockIdx: 1))
    #expect(1 == BlockHash.computeBlockSize(fileSize: BlockSize*2 + 1, blockIdx: 2))
}
