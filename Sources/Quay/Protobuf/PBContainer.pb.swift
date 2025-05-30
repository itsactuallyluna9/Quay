// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: Sources/Quay/Protobuf/PBContainer.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct PBContainer: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var files: [PBFile] = []

  var dirs: [PBDir] = []

  var symlinks: [PBSymlink] = []

  var size: Int64 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct PBDir: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var path: String = String()

  var mode: UInt32 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct PBFile: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var path: String = String()

  var mode: UInt32 = 0

  var size: Int64 = 0

  var offset: Int64 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct PBSymlink: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var path: String = String()

  var mode: UInt32 = 0

  var dest: String = String()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension PBContainer: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "PBContainer"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "files"),
    2: .same(proto: "dirs"),
    3: .same(proto: "symlinks"),
    16: .same(proto: "size"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedMessageField(value: &self.files) }()
      case 2: try { try decoder.decodeRepeatedMessageField(value: &self.dirs) }()
      case 3: try { try decoder.decodeRepeatedMessageField(value: &self.symlinks) }()
      case 16: try { try decoder.decodeSingularInt64Field(value: &self.size) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.files.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.files, fieldNumber: 1)
    }
    if !self.dirs.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.dirs, fieldNumber: 2)
    }
    if !self.symlinks.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.symlinks, fieldNumber: 3)
    }
    if self.size != 0 {
      try visitor.visitSingularInt64Field(value: self.size, fieldNumber: 16)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: PBContainer, rhs: PBContainer) -> Bool {
    if lhs.files != rhs.files {return false}
    if lhs.dirs != rhs.dirs {return false}
    if lhs.symlinks != rhs.symlinks {return false}
    if lhs.size != rhs.size {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension PBDir: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "PBDir"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "path"),
    2: .same(proto: "mode"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.path) }()
      case 2: try { try decoder.decodeSingularUInt32Field(value: &self.mode) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.path.isEmpty {
      try visitor.visitSingularStringField(value: self.path, fieldNumber: 1)
    }
    if self.mode != 0 {
      try visitor.visitSingularUInt32Field(value: self.mode, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: PBDir, rhs: PBDir) -> Bool {
    if lhs.path != rhs.path {return false}
    if lhs.mode != rhs.mode {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension PBFile: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "PBFile"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "path"),
    2: .same(proto: "mode"),
    3: .same(proto: "size"),
    4: .same(proto: "offset"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.path) }()
      case 2: try { try decoder.decodeSingularUInt32Field(value: &self.mode) }()
      case 3: try { try decoder.decodeSingularInt64Field(value: &self.size) }()
      case 4: try { try decoder.decodeSingularInt64Field(value: &self.offset) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.path.isEmpty {
      try visitor.visitSingularStringField(value: self.path, fieldNumber: 1)
    }
    if self.mode != 0 {
      try visitor.visitSingularUInt32Field(value: self.mode, fieldNumber: 2)
    }
    if self.size != 0 {
      try visitor.visitSingularInt64Field(value: self.size, fieldNumber: 3)
    }
    if self.offset != 0 {
      try visitor.visitSingularInt64Field(value: self.offset, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: PBFile, rhs: PBFile) -> Bool {
    if lhs.path != rhs.path {return false}
    if lhs.mode != rhs.mode {return false}
    if lhs.size != rhs.size {return false}
    if lhs.offset != rhs.offset {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension PBSymlink: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "PBSymlink"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "path"),
    2: .same(proto: "mode"),
    3: .same(proto: "dest"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.path) }()
      case 2: try { try decoder.decodeSingularUInt32Field(value: &self.mode) }()
      case 3: try { try decoder.decodeSingularStringField(value: &self.dest) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.path.isEmpty {
      try visitor.visitSingularStringField(value: self.path, fieldNumber: 1)
    }
    if self.mode != 0 {
      try visitor.visitSingularUInt32Field(value: self.mode, fieldNumber: 2)
    }
    if !self.dest.isEmpty {
      try visitor.visitSingularStringField(value: self.dest, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: PBSymlink, rhs: PBSymlink) -> Bool {
    if lhs.path != rhs.path {return false}
    if lhs.mode != rhs.mode {return false}
    if lhs.dest != rhs.dest {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
