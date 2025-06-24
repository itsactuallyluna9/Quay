import ArgumentParser
import ConsoleKitTerminal
import Foundation
import Quay

@main
struct Hedge: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "mewo",
        version: VersionatorVersion.full,
        subcommands: [
            Sign.self,
            Diff.self,
            Apply.self,
            Verify.self
        ]
    )
}

struct GenericOptions: ParsableArguments {
    // @Flag(name: .customLong("json"), help: "Output in JSON format")
    // var json: Bool = false
    
    // @Flag(name: .customLong("verbose"), help: "Be more verbose about what is going on")
    // var verbose: Bool = false

    // @Flag(name: .customLong("ignore"), help: "Glob patterns of files to ignore")
    // var ignore: [String] = []
}

extension Hedge {
    struct Sign: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "sign"
        )

        @OptionGroup var options: GenericOptions

        @Argument(help: "Path of the directory to sign")
        var path: String

        @Argument(help: "Path to write signature to")
        var output: String

        mutating func run() throws {
            let terminal = Terminal()

            terminal.info("Creating signature for \(path)")

            var signature = try Quay.sign(dir: URL(fileURLWithPath: path))

            let totalSize = signature.container.files.reduce(0) { $0 + $1.size }
            let numFiles = signature.container.files.count
            let numDirs = signature.container.directories.count
            let numSymlinks = signature.container.symlinks.count
            let totalSizeString = ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
            let numFilesString = NumberFormatter.localizedString(from: NSNumber(value: numFiles), number: .decimal)
            let numDirsString = NumberFormatter.localizedString(from: NSNumber(value: numDirs), number: .decimal)
            let numSymlinksString = NumberFormatter.localizedString(from: NSNumber(value: numSymlinks), number: .decimal)

            terminal.success("[ok] \(totalSizeString) (\(numFilesString) files, \(numDirsString) dirs, \(numSymlinksString) symlinks)", newLine: true)
            // TODO: actually fix the stuff to write the signature
            let outputURL = URL(fileURLWithPath: output)
        }
    }

    struct Diff: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "diff"
        )

        @OptionGroup var options: GenericOptions

        @Argument(help: "Drectroy with older files, or a signature file generated from it")
        var target: String

        @Argument(help: "Directory with newer files")
        var source: String

        @Argument(help: "Path to write patch and signature file to (signature will be written to this path with .sig extension)")
        var output: String

        mutating func run() throws {
            let terminal = Terminal()

            terminal.info("Diffing \(target) against \(source)")

            var diffResult = try Quay.diff(target: URL(fileURLWithPath: target), source: URL(fileURLWithPath: source))
            terminal.warning("Not implemented yet")

            // TODO: same thing as in sign
        }
    }

    struct Apply: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "apply"
        )

        @OptionGroup var options: GenericOptions

        @Argument(help: "Patch file to apply")
        var patch: String

        @Argument(help: "Directory to apply the patch to files")
        var to: String

        mutating func run() throws {
            let terminal = Terminal()

            terminal.info("Applying \(patch) to \(to)")
            terminal.warning("Not implemented yet")

            // Quay.apply(patch: WharfPatch, to: URL, stagingDir: URL?)
        }
    }

    struct Verify: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "verify"
        )

        @OptionGroup var options: GenericOptions

        @Argument(help: "Path to the signature file")
        var signature: String

        @Argument(help: "Path to the directory to verify")
        var dir: String

        mutating func run() throws {
            let terminal = Terminal()

            terminal.info("Verifying \(signature) against \(dir)")
            terminal.warning("Not implemented yet")

            // let result = try Quay.verify(signature: URL(fileURLWithPath: signature), dir: URL(fileURLWithPath: dir))

            // if result {
            //     terminal.success("[ok] signature verified")
            // } else {
            //     terminal.error("[fail] signature verification failed")
            // }
        }
    }
}
