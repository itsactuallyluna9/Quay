import Testing
import Foundation
@testable import Quay

struct Container {
    @Test()
    func readsFromProtobuf() async throws {
        let data = Data(base64Encoded: "ChAKCWhlbGxvLnR4dBCkAxgOChkKEHNhbXBsZS9pbWFnZS5wbmcQpAMYgIAEEgwKBnNhbXBsZRDtgwQaIgoJaW1hZ2UucG5nEKSDgEAaEHNhbXBsZS9pbWFnZS5wbmc=")
        try #require(data != nil)

        let container = try QuayContainer(protobuf: data!)
        #expect(container.directories.count == 1)
        #expect(container.files.count == 2)
        #expect(container.symlinks.count == 1)
    }

    @Test()
    func constructsFromFolder() async throws {
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
        #expect(data.base64EncodedString() == "ChAKCWhlbGxvLnR4dBCkAxgOChkKEHNhbXBsZS9pbWFnZS5wbmcQpAMYgIAEEgwKBnNhbXBsZRDtgwQaIgoJaW1hZ2UucG5nEKSDgEAaEHNhbXBsZS9pbWFnZS5wbmc=")
    }
}
