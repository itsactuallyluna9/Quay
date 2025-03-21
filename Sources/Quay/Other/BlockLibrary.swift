package func constructBlockLibrary(hashes: [BlockHash]) -> Dictionary<UInt32, [BlockHash]> {
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
