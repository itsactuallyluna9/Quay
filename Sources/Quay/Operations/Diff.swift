import Foundation

public extension Quay {
    /// Compute the difference between two directories.
    ///
    /// - Parameters:
    ///   - target: Directory with older files.
    ///   - source: Directory with newer files.
    /// - Returns:
    ///   - patch: A patch file containing the differences between the two directories.
    ///   - signature: The new directory's signature.
    static func diff(target: URL, source: URL) throws -> (patch: WharfPatch, signature: WharfSignature) {
        // Step 1: Get signature of target directories
        let targetSignature = try loadOrMakeSignature(for: target)

        return try diff(target: targetSignature, source: source)
    }

    /// Compute the difference between two directories.
    ///
    /// - Parameters:
    ///   - target: Signature file generated from the new directory.
    ///   - source: Directory with newer files.
    /// - Returns:
    ///   - patch: A patch file containing the differences between the two directories.
    ///   - signature: The new directory's signature.
    static func diff(target: WharfSignature, source: URL) throws -> (patch: WharfPatch, signature: WharfSignature) {
        // Step 2: Generate the patch and signature on-the-fly
        // TODO: generate signature while creating the patch
        let patch = try WharfPatch(target: target, source: source)
        let signature = try sign(dir: source)

        // Step 3: Return the patch and the new signature
        return (patch: patch, signature: signature)
    }

    package static func loadOrMakeSignature(for url: URL) throws -> WharfSignature {
        // if /dev/null, return empty
        if url == URL(fileURLWithPath: "/dev/null") {
            return .init(header: .init(compression: .none), container: .empty, blockHashes: [])
        }
        // Step 1: Check if the file exists
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && !isDirectory.boolValue {
            // Step 2: Load the signature
            do {
                return try WharfSignature(file: url)
            } catch {
                // ...is it because we don't have the magic number?
                let nsError = error as NSError
                if nsError.domain == "Quay" && nsError.code == Quay.ErrorCode.invalidMagicNumber.rawValue {
                    // Step 2a: If so, try to generate a new signature. It's probably a single file diff.
                    return try sign(dir: url)
                }
                // Step 2b: Otherwise, rethrow the error
                throw error
            }
        } else {
            // It's a folder! (Probably.)
            // Step 3: Generate a new signature
            return try sign(dir: url)
        }
    }
}
