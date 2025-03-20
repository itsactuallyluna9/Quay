import Foundation

extension Data {
    func readUInt8(at: Int? = nil) -> UInt8 {
        return self.dropFirst(at ?? 0).prefix(1).withUnsafeBytes { rawBuf in
            rawBuf.load(as: UInt8.self).littleEndian
        }
    }
    
    func readInt32(at: Int? = nil) -> Int32 {
        return self.dropFirst(at ?? 0).prefix(4).withUnsafeBytes { rawBuf in
            rawBuf.load(as: Int32.self).littleEndian
        }
    }
}
