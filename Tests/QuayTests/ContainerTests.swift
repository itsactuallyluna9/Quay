import Testing
import Foundation
@testable import Quay

struct Container {
    @Test()
    func readsFromProtobuf() async throws {
        let data = Data(base64Encoded: "ChAKCWhlbGxvLnR4dBCkAxgOChkKEHNhbXBsZS9pbWFnZS5wbmcQpAMYgIAEEgwKBnNhbXBsZRDtgwQaIgoJaW1hZ2UucG5nEKSDgEAaEHNhbXBsZS9pbWFnZS5wbmeAAY6ABA==")
        try #require(data != nil)

        let container = try QuayContainer(protobuf: data!)
        #expect(container.directories.count == 1)
        #expect(container.files.count == 2)
        #expect(container.symlinks.count == 1)
    }

    @Test()
    func constructsFromFolder() async throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { cleanupTestDir(at: tempDir) }

        try makeTestDir(at: tempDir, settings: .init(entries: [
            // create a few files to test signing
            .init(path: "hello.txt", data: "Hello, World!\n".data(using: .utf8)),
            .init(path: "sample/image.png", size: 64*1024, seed: 0x2),
            .init(path: "image.png", dest: "sample/image.png")
        ]))

        let container = try QuayContainer(folder: tempDir)
        #expect(container.directories.count == 1)
        #expect(container.files.count == 2)
        // #expect(container.files.map { $0.name } == ["hello.txt", "sample/image.png"])
        #expect(container.files.map { $0.permissions } == [0o644, 0o644])
        #expect(container.symlinks.count == 1)
        #expect(container.symlinks.first?.target == "sample/image.png")
    }

    @Test()
    func encodesToProtobuf() async throws {
        let container = QuayContainer(directories: [
            .init(name: "sample", permissions: UInt32(0o755 | 0x10000))
        ], files: [
            .init(name: "hello.txt", permissions: 0o644, size: 14),
            .init(name: "sample/image.png", permissions: 0o644, size: 64*1024)
        ], symlinks: [
            .init(name: "image.png", target: "sample/image.png", permissions: UInt32(0o644 | 0x8000000))
        ])

        let data = try container.protobuf().serializedData()
        #expect(data.base64EncodedString() == "ChAKCWhlbGxvLnR4dBCkAxgOChkKEHNhbXBsZS9pbWFnZS5wbmcQpAMYgIAEEgwKBnNhbXBsZRDtgwQaIgoJaW1hZ2UucG5nEKSDgEAaEHNhbXBsZS9pbWFnZS5wbmeAAY6ABA==")
    }
}
