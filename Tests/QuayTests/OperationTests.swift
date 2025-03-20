import Testing
import Foundation
@testable import Quay

struct OperationTests {
    @Suite("Sign")
    struct SignTests {
        @Test func signsDirectory() async throws {
            let fm = FileManager.default
            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            try fm.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
            defer { try? fm.removeItem(at: tempDir) }

            // make a sample directory
            let sampleDir = tempDir.appendingPathComponent("sample")
            try fm.createDirectory(at: sampleDir, withIntermediateDirectories: true, attributes: nil)
            try "Hello, World!".write(to: tempDir.appendingPathComponent("hello.txt"), atomically: true, encoding: .utf8)
            try Data(count: 64*1024).write(to: sampleDir.appendingPathComponent("image.png"))
            try fm.createSymbolicLink(at: tempDir.appendingPathComponent("image.png"), withDestinationURL: sampleDir.appendingPathComponent("image.png"))

            var signature = try Quay.sign(dir: tempDir)
            #expect(signature.container.directories.count == 1)
            #expect(signature.container.files.count == 2)
            #expect(signature.container.symlinks.count == 1)
            #expect(signature.blockHashes.count == 2)

            signature.header.compression = .none

            let data = try signature.encode()
            #expect(data.base64EncodedData().md5().toHexString() == "43b45d39afca776f27d971467291c6fc")
        }
    }
}
