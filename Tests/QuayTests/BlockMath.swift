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

@Test("", .disabled()) func testComputeBlockSize() async throws {
//    #expect(0, BlockHash.computeBlockSize())
}
