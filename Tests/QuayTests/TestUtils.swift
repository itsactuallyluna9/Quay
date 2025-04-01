import Foundation

// Same as in Shared.swift
let BlockSize: Int = 64 * 1024 // 64 KiB

struct TestDirSettings {
	struct Entry {
		let path: String
		var mode: Int? = nil
		var size: Int? = nil
		var seed: UInt64? = nil
		var dir: Bool = false
		var dest: String = ""
		var chunks: [Chunk]? = nil
		var data: Data? = nil
	}

	struct Chunk {
		let seed: UInt64
		let size: Int
	}

	var seed: UInt64? = nil
	let entries: [Entry]
}

// Taken from https://github.com/swiftlang/swift/blob/a5e6a7f6d91d7e51192fe0a2eace351ccf4df88a/benchmark/utils/TestsUtils.swift#L247-L268
// (Adding a new `seed` function, though.)
// This is a fixed-increment version of Java 8's SplittableRandom generator.
// It is a very fast generator passing BigCrush, with 64 bits of state.
// See http://dx.doi.org/10.1145/2714064.2660195 and
// http://docs.oracle.com/javase/8/docs/api/java/util/SplittableRandom.html
//
// Derived from public domain C implementation by Sebastiano Vigna
// See http://xoshiro.di.unimi.it/splitmix64.c
public struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func next() -> UInt64 {
        self.state &+= 0x9e3779b97f4a7c15
        var z: UInt64 = self.state
        z = (z ^ (z &>> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z &>> 27)) &* 0x94d049bb133111eb
        return z ^ (z &>> 31)
    }

	public mutating func seed(_ seed: UInt64) {
		self.state = seed
	}
}


func makeTestDir(at: URL, settings: TestDirSettings) throws {
	let fm = FileManager.default
	var rng = SplitMix64(seed: settings.seed ?? 0)
	var buf = Data()

	try fm.createDirectory(at: at, withIntermediateDirectories: true)

	for entry in settings.entries {
		let path = at.appendingPathComponent(entry.path)

		if entry.dir {
			// dir
			let mode = entry.mode ?? 0o755
			try fm.createDirectory(at: path, withIntermediateDirectories: true)
			try fm.setAttributes([.posixPermissions: mode], ofItemAtPath: path.path)
			continue
		} else if entry.dest != "" {
			// symlink
			try fm.createSymbolicLink(at: path, withDestinationURL: at.appendingPathComponent(entry.dest))
			continue
		}

		// file

		let parent = path.deletingLastPathComponent()
		try fm.createDirectory(at: parent, withIntermediateDirectories: true)

		rng.seed(entry.seed ?? settings.seed ?? 0)

		let mode = entry.mode ?? 0o644
		let size = entry.size ?? (BlockSize * 8) + 64

		if size < 0 {
			continue
		}


		if let entryData = entry.data {
			buf = entryData
		} else if let chunks = entry.chunks {
			for chunk in chunks {
				rng.seed(chunk.seed)
				// fill the buffer with random data
				var chunkBuf = Data(count: Int(chunk.size))
				chunkBuf.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
					let base = ptr.baseAddress!.assumingMemoryBound(to: UInt8.self)
					for i in 0..<chunk.size {
						base[i] = UInt8(rng.next() & 0xff)
					}
				}
				buf.append(chunkBuf)
			}
		} else {
			// fill the buffer with random data
			buf = Data(count: size)
			buf.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
				let base = ptr.baseAddress!.assumingMemoryBound(to: UInt8.self)
				for i in 0..<size {
					base[i] = UInt8(rng.next() & 0xff)
				}
			}
		}

		try buf.write(to: path)
		try fm.setAttributes([.posixPermissions: mode], ofItemAtPath: path.path)

		buf.removeAll(keepingCapacity: true)
	}
}

func cleanupTestDir(at: URL) {
	// remove the directory, recursively
	let fm = FileManager.default
	try? fm.removeItem(at: at) // ignore errors
}
