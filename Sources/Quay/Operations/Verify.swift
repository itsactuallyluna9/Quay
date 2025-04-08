import Foundation

public enum Wound: Equatable {    
    case directory(index: Int)
    case symlink(index: Int)
    case file(index: Int)
}

public struct VerificationResult {
    public package(set) var wounds: [Wound] = []

    public var okay: Bool {
        return wounds.isEmpty
    }
}

public extension Quay {
    /// Verify the integrity of a directory.
    ///
    /// Will only check against the contents of the signature file, and won't error on any additional files not present
    /// in the signature. (This is so save data will not be flagged.)
    ///
    /// - Parameters:
    ///   - signature: The signature to use.
    ///   - dir: The directory to verify.
    static func verify(signature: WharfSignature, dir: URL) throws -> VerificationResult {
        // Check directories and symlinks...
        var results = VerificationResult()
        
        for (idx, directory) in signature.container.directories.enumerated() {
            // Check if the directory exists
            let toCheck = dir.appendingPathComponent(directory.name)
            if let v = try? toCheck.resourceValues(forKeys: [.isDirectoryKey]) {
                if v.isDirectory! {
                    continue
                }
            }
            // if we're here: it either doesn't exist or isn't a directory
            results.wounds.append(.directory(index: idx))
        }
        
        for (idx, symlink) in signature.container.symlinks.enumerated() {
            let toCheck = dir.appendingPathComponent(symlink.name)
            if let v = try? toCheck.resourceValues(forKeys: [.isSymbolicLinkKey]) {
                if v.isSymbolicLink! {
                    // check if the symlink points to the expected target
                    let targetPath = try? FileManager.default.destinationOfSymbolicLink(atPath: toCheck.path)
                    if let targetPath = targetPath, URL(fileURLWithPath: targetPath, relativeTo: dir) == dir.appendingPathComponent(symlink.target) {
                        continue
                    }
                }
            }
            // if we're here: it either doesn't exist, isn't a symlink, or it's not pointing to the right spot
            results.wounds.append(.symlink(index: idx))
        }
        
        // Check files
        for fileIdx in signature.container.files.indices {
            #warning("Validating files not yet implemented!")
        }
        
        return results
    }
}
