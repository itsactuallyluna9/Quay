import Foundation

public struct QuayContainer: ProtobufAlias, Equatable {
    typealias PBMessage = PBContainer

    public struct Directory : ProtobufAlias, Equatable {
        typealias PBMessage = PBDir
        public private(set) var name: String
        public private(set) var permissions: UInt32
        
        init(name: String, permissions: UInt32) {
            self.name = name
            self.permissions = permissions
        }
        
        init(protobuf: PBDir) {
            self.name = protobuf.path
            self.permissions = protobuf.mode & 0xFFFF
        }

        func protobuf() -> PBDir {
            var dir = PBDir()
            dir.path = name
            dir.mode = permissions | 0x10000
            return dir
        }
    }

    public struct File : ProtobufAlias, Equatable {
        typealias PBMessage = PBFile

        public private(set) var name: String
        public private(set) var permissions: UInt32
        public private(set) var size: Int
        
        init(name: String, permissions: UInt32, size: Int) {
            self.name = name
            self.permissions = permissions
            self.size = size
        }
        
        init (protobuf: PBFile) {
            self.name = protobuf.path
            self.permissions = protobuf.mode
            self.size = Int(protobuf.size)
        }

        func protobuf() -> PBFile {
            var file = PBFile()
            file.path = name
            file.mode = permissions
            file.size = Int64(size)
            return file
        }
    }

    public struct Symlink : ProtobufAlias, Equatable {
        typealias PBMessage = PBSymlink

        public private(set) var name: String
        public private(set) var target: String
        public private(set) var permissions: UInt32
        
        init(name: String, target: String, permissions: UInt32) {
            self.name = name
            self.target = target
            self.permissions = permissions
        }
        
        init(protobuf: PBSymlink) {
            self.name = protobuf.path
            self.target = protobuf.dest
            self.permissions = protobuf.mode & 0xFFFF
        }

        func protobuf() -> PBSymlink {
            var symlink = PBSymlink()
            symlink.path = name
            symlink.dest = target
            symlink.mode = permissions | 0x8000000
            return symlink
        }
    }

    public private(set) var directories: [Directory] = []
    public private(set) var files: [File] = []
    public private(set) var symlinks: [Symlink] = []
    
    public static let empty: QuayContainer = .init(directories: [], files: [], symlinks: [])
    
    public init(directories: [Directory] = [], files: [File] = [], symlinks: [Symlink] = []) {
        self.directories = directories
        self.files = files
        self.symlinks = symlinks
    }
    
    public init(folder: URL) throws {
        // Alright, we need to recursively scan...
        let fm = FileManager.default
        
        func scan(_ url: URL, relativePath: String = "") throws {
            let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey]
            let contents = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: keys)
            
            for item in contents {
                let resourceValues = try item.resourceValues(forKeys: Set(keys))
                let itemRelativePath = relativePath.isEmpty ? item.lastPathComponent : "\(relativePath)/\(item.lastPathComponent)"
                let permissions = try fm.attributesOfItem(atPath: item.path)[.posixPermissions] as? UInt32 ?? 0o777
                
                if resourceValues.isDirectory == true {
                    directories.append(.init(name: itemRelativePath, permissions: permissions))
                    try scan(item, relativePath: itemRelativePath)
                } else if resourceValues.isSymbolicLink == true {
                    let dest = try fm.destinationOfSymbolicLink(atPath: item.path)
                    let targetURL = URL(fileURLWithPath: dest)
                    let relativeDest: String
                    if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
                        relativeDest = targetURL.path.replacingOccurrences(of: folder.path() + "/", with: "")
                    } else {
                        relativeDest = targetURL.path.replacingOccurrences(of: folder.path + "/", with: "")
                    }
                    symlinks.append(.init(name: itemRelativePath, target: relativeDest, permissions: permissions))
                } else {
                    files.append(.init(name: itemRelativePath, permissions: permissions, size: resourceValues.fileSize ?? 0))
                }
            }
        }
        
        try scan(folder)
    }
    
    init(protobuf: PBContainer) {
        self.directories = protobuf.dirs.map { Directory.init(protobuf: $0) }
        self.files = protobuf.files.map { File.init(protobuf: $0) }
        self.symlinks = protobuf.symlinks.map { Symlink.init(protobuf: $0) }
    }

    public func iterFiles(_ root: URL?) -> AnyIterator<URL> {
        var urls: [URL] = []
        for file in files {
            let url = root?.appendingPathComponent(file.name) ?? URL(fileURLWithPath: file.name)
            urls.append(url)
        }
        return AnyIterator(urls.makeIterator())
    }

    func protobuf() -> PBContainer {
        var container = PBContainer()
        container.dirs = directories.map { $0.protobuf() }
        container.files = files.map { $0.protobuf() }
        container.symlinks = symlinks.map { $0.protobuf() }
        container.size = Int64(files.reduce(0) { $0 + $1.size })
        return container
    }
}
