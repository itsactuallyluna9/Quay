import Testing
import Foundation
@testable import Quay

struct OperationTests {
    @Suite("Sign")
    struct SignTests {
        @Test func signsDirectory() async throws {
            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            defer { cleanupTestDir(at: tempDir) }

            try makeTestDir(at: tempDir, settings: .init(entries: [
                // create a few files to test signing
                .init(path: "hello.txt", data: "Hello, World!\n".data(using: .utf8)),
                .init(path: "sample/image.png", size: 64*1024, seed: 0x2),
                .init(path: "image.png", dest: "sample/image.png")
            ]))

            let signature = try Quay.sign(dir: tempDir)
            #expect(signature.container.directories.count == 1)
            #expect(signature.container.files.count == 2)
            #expect(signature.container.symlinks.count == 1)
            #expect(signature.blockHashes.count == 2)
        }
    }
}
