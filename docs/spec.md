# Spec

## Warning

This is reverse engineered! Good luck.

## General Notes
* All protobufs are proceeded by a uint8 for length.

## Patch

* Int32 Magic Number
* Header (Protobuf `PatchHeader`)
* Body (can be compressed, see header)
    * TargetContainer (from... somewhere)
    * SourceContainer (from... somewhere)
    * Files (based off of SourceContainer??)
        * Protobuf `SyncHeader`
        * Protobuf ????????????...
        * Protobuf `SyncOp` (HEY_YOU_DID_IT)

## Sig

* Int32 Magic Number
* Header (Protobuf `SignatureHeader`)
* Body (can be compressed, see header)
    * Container (from????)
    * Files
        * Protobuf BlockHash(es)...
