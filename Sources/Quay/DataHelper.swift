import Foundation

extension Data {
    func readUInt8(at: Int? = nil) -> UInt8 {
        return self.dropFirst(at ?? 0).prefix(1).withUnsafeBytes { rawBuf in
            rawBuf.load(as: UInt8.self).littleEndian
        }
    }

    func readUVarInt(offset: Int = 0) throws -> (value: UInt64, bytesRead: Int) {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        var bytesRead = 0
        
        for i in 0..<9 { // Maximum of 9 bytes for a 64-bit integer
            if offset + i >= self.count {
                throw Quay.createError(.decodeFailed, description: "Decode failure", failureReason: "Unexpected end of data when reading message length")
            }
            
            let b = self[offset + i]
            bytesRead += 1
            
            // Add the lower 7 bits to our result
            result |= UInt64(b & 0x7F) << shift
            
            // If the high bit is not set, we're done
            if (b & 0x80) == 0 {
                return (result, bytesRead)
            }
            
            // Move to the next 7 bits
            shift += 7
            
            // Check for overflow
            if shift >= 64 {
                throw Quay.createError(.decodeFailed, description: "Decode failure", failureReason: "Extracted message length is too large")
            }
        }
        
        // If we get here, the encoding is invalid (too many bytes)
        throw Quay.createError(.decodeFailed, description: "Decode failure", failureReason: "Extracted message length is too large")
    }
    
    func readInt32(at: Int? = nil) -> Int32 {
        return self.dropFirst(at ?? 0).prefix(4).withUnsafeBytes { rawBuf in
            rawBuf.load(as: Int32.self).littleEndian
        }
    }
}

func encodeUVarInt(value: UInt64) -> Data {
    var value = value
    var data = Data()
    repeat {
        var byte = UInt8(value & 0x7F)
        value >>= 7
        if value != 0 {
            byte |= 0x80
        }
        data.append(byte)
    } while value != 0
    return data
}
