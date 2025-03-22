import Foundation

public extension Quay {
    /// Generate a signgature file for a given directory. Useful for integrity checks and remote diff generation.
    ///
    /// - Parameters:
    ///   - dir: Directory to generate a signature for.
    static func sign(dir: URL) throws -> WharfSignature {
        // Alright, let's build our container...
        let progress = Progress(totalUnitCount: 100)
        progress.becomeCurrent(withPendingUnitCount: 20)
        let container = try QuayContainer.init(folder: dir)
        progress.resignCurrent()
        
        // Now, we need to actually generate signatures for everything...
        progress.becomeCurrent(withPendingUnitCount: 80)
        let hashes = try container.files.flatMap { file in
            let fileURL = dir.appendingPathComponent(file.name)
            return try BlockHash.generateHashes(for: fileURL)
        }
        progress.resignCurrent()

        return .init(header: .init(compression: .transportDefault), container: container, blockHashes: hashes)
    }
}
