import Foundation

public extension Quay {
    /// Generate a signgature file for a given directory. Useful for integrity checks and remote diff generation.
    ///
    /// - Parameters:
    ///   - dir: Directory to generate a signature for.
    static func sign(dir: URL) throws -> WharfSignature {
        // Alright, let's build our container...
        let container = try QuayContainer.init(folder: dir)
        
        // Now, we need to actually generate signatures for everything...
        let hashes = try container.files.map { file in
            let fileURL = dir.appendingPathComponent(file.name)
            return try BlockHash.generateHashes(for: fileURL)
        }.flatMap { $0 }

        return .init(header: .init(compression: .transportDefault), container: container, blockHashes: hashes)
    }
}
