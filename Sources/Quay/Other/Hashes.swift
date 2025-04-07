import Foundation
import Crypto

package struct MD5Hash {
    private var hasher = Insecure.MD5()
    private(set) var hash: Data?
    
    init() {}
    
    init(block: any DataProtocol) {
        update(withBytes: block)
    }
    
    mutating func update(withBytes: any DataProtocol) {
        hasher.update(data: withBytes)
    }
    
    mutating func update(withByte byte: UInt8) {
        hasher.update(data: [byte])
    }
    
    mutating func reset() {
        hash = nil
        hasher = Insecure.MD5()
    }
    
    mutating func finalize() -> Data {
        hash = Data(hasher.finalize())
        return hash! // i've literally just set it
    }
    
    static func immediateHash(of block: any DataProtocol) -> Data {
        var hasher = Insecure.MD5()
        hasher.update(data: block)
        return Data(hasher.finalize())
    }
}

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

    init(block: any DataProtocol) {
        buffer = Array(repeating: 0, count: WeakRollingHash.bufferSize)
        update(withBytes: block)
    }

    mutating func update(withBytes: any DataProtocol) {
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
