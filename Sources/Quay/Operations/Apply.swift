import Foundation

private func applyPreProcess(container: QuayContainer, target: URL) throws {
    let fm = FileManager.default

    // Ensure the target directory exists
    if !fm.fileExists(atPath: target.path) {
        try fm.createDirectory(at: target, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o755])
    }

    for dir in container.directories {
        try prepareDirectory(dir: dir, target: target)
    }

    for file in container.files {
        try prepareFile(file: file, target: target)
    }

    for link in container.symlinks {
//        try prepareSymlink(link: link, target: target)
    }
}

private func prepareDirectory(dir: QuayContainer.Directory, target: URL) throws {
    let fm = FileManager.default
    let dirPath = target.appendingPathComponent(dir.name)

    if !fm.fileExists(atPath: dirPath.path) {
        try fm.createDirectory(at: dirPath, withIntermediateDirectories: true, attributes: [.posixPermissions: dir.permissions])
    } else {
        // If it exists, ensure the permissions are set correctly
        try fm.setAttributes([.posixPermissions: dir.permissions], ofItemAtPath: dirPath.path)
    }
}

private func prepareFile(file: QuayContainer.File, target: URL) throws {
    let fm = FileManager.default
    let filePath = target.appendingPathComponent(file.name)
}

public extension Quay {
    /// Apply a patch to a directory.
    /// 
    /// - Parameters:
    ///   - patch: The patch to apply.
    ///   - old: The directory to apply the patch to (the "old" version).
    ///   - new: The directory to write the patched version to (the "new" version).
    ///   - stagingDir: A directory for temporary files, or `nil` to use the system temporary directory.
    static func apply(patch: WharfPatch, old: URL, new: URL, stagingDir: URL?) throws {
        let stagingDir = stagingDir ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        // Step 1: Pre-Processing
        // Missing directories/files should be created
        try applyPreProcess(container: patch.sourceContainer, target: stagingDir)

        // Step 2: Apply!
        var currentFile: FileHandle? = nil
        for op in patch.syncOps {
            switch op {
            case .startFile(algorithm: let algo, fileIndex: let fileIndex):
                switch algo {
                case .rsync:
                    break
                case .bsdiff:
                    throw Quay.createError(.unimplemented, description: "BSDiff not implemented!", failureReason: "BSDiff isn't implemented :<")
                }
                
                let fp = patch.sourceContainer.files[fileIndex].name
                try "".write(to: stagingDir.appendingPathComponent(fp), atomically: true, encoding: .ascii)
                currentFile = try FileHandle(forWritingTo: stagingDir.appendingPathComponent(fp))
                
                break
            case .data(data: let data):
                // write data at the current offset
                currentFile!.write(data)
                break
            case .blockRange(sourceFileIndex: let fileIndex, blockIndex: let blockIndex, blockSpan: let blockSpan):
                // Block range!
                // figure out what to read...
                let sourceFile = patch.targetContainer.files[fileIndex]
                let sourceFilePath = old.appendingPathComponent(sourceFile.name)
                let read = try Data(contentsOf: sourceFilePath).subdata(in: Range(BlockHash.computeBlockSize(fileSize: sourceFile.size, blockIdx: blockIndex)...BlockHash.computeBlockSize(fileSize: sourceFile.size, blockIdx: blockIndex + blockSpan)))
                // now write the thing
                currentFile?.write(read)
                break
            case .heyYouDidIt:
                // hey we did it
                currentFile!.closeFile()
                break
            }
        }


        // Step n: Post-Processing

        if old == new {
            // Symlinks
            // Files in new but not in old should be deleted
            // Directories in new but not in old should be removed if they are empty

            // TODO: above
        } else {
            // Copy the staged directory to the new location
            let fm = FileManager.default
            if fm.fileExists(atPath: new.path) {
                try fm.removeItem(at: new)
            }
            try fm.copyItem(at: stagingDir, to: new)
            
            // Symlinks
            for link in patch.sourceContainer.symlinks {
                let linkPath = new.appendingPathComponent(link.name)
                let targetPath = new.appendingPathComponent(link.target)
                try FileManager.default.createSymbolicLink(at: linkPath, withDestinationURL: targetPath)
            }
        }

    }

    /// Apply a patch to a directory, in-place.
    /// 
    /// - Parameters:
    ///   - patch: The patch to apply.
    ///   - to: The directory to apply the patch to.
    ///   - stagingDir: A directory for temporary files, or `nil` to use the system temporary directory.
    static func apply(patch: WharfPatch, to: URL, stagingDir: URL?) throws {
        return try apply(patch: patch, old: to, new: to, stagingDir: stagingDir)
    }
}
