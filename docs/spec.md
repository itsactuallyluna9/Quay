# Spec

> [!WARNING]
> This is (somewhat) reverse engineered, with stuff (if able) being pulled from [the official specification](https://docs.itch.ovh/wharf/master/), and, if not, from the [reference Go implementation](https://github.com/itchio/wharf), or by manually dissecting sample files generated using [their command line tool](https://github.com/itchio/butler).

Good luck.

## General Notes

* All protobufs are proceeded by a `UVarInt`, which is the length of the following protobuf.
* All headers are uncompressed protobufs. Bodies *can* be compressed based on the compression settings defined in the header.
    * The optionally compressed body starts immediately after the header, with no length prefix.


## File Structure

### Patch (.pwr)

* Int32 Magic Number
* Header (Protobuf `PatchHeader`)
* Body (can be compressed, see header)
    * TargetContainer (Protobuf `Container`)
    * SourceContainer (Protobuf `Container`)
    * Files (based off of SourceContainer??)
        * Protobuf `SyncHeader`
        * (many) Protobuf `SyncOp` (not HEY_YOU_DID_IT)
        * Protobuf `SyncOp` (HEY_YOU_DID_IT)

### Signature (.sig)

* Int32 Magic Number
* Header (Protobuf `SignatureHeader`)
* Body (can be compressed, see header)
    * Container (Protobuf `Container`)
    * Files
        * (many) Protobuf BlockHash

## Algorithms

### Sign

### Diff

### Apply
