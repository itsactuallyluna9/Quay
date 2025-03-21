package func constructBlockLibrary(signature: WharfSignature) -> Dictionary<UInt32, [BlockHash]> {
    // clone the hashes
    var hashes = signature.blockHashes

    // anchor the hashes
    anchorBlockHashes(hashes: &hashes, container: signature.container)

    var library: Dictionary<UInt32, [BlockHash]> = [:]
    for hash in hashes {
        let key = hash.weakHash
        if library[key] == nil {
            library[key] = [hash]
        } else {
            library[key]?.append(hash)
        }
    }
    return library
}

func anchorBlockHashes(hashes: inout [BlockHash], container: QuayContainer) {
    let fullBlockSize = 64 * 1024

    var fileIndex = 0
    var blockIndex = 0
    let blockSize = fullBlockSize
    var byteOffset = 0

    for i in 0..<hashes.count {
        var sizeDiff = container.files[fileIndex].size - byteOffset
        var shortSize = 0

        if sizeDiff < 0 {
            // moved past the end of the file
            byteOffset = 0
            blockIndex = 0
            fileIndex += 1
            sizeDiff = container.files[fileIndex].size - byteOffset
        }

        if (sizeDiff < fullBlockSize) {
            // last block of the file
            shortSize = sizeDiff
        } else {
            shortSize = 0
        }

        // anchor
        hashes[i].anchor(fileIndex: fileIndex, blockIndex: blockIndex, shortSize: shortSize)

        byteOffset += blockSize
        blockIndex += 1
    }
}
