import Foundation

public enum Magic: Int32 {
    /// Magic number for wharf patch files. (.pwr)
    case patch = 0xfef5f00
    /// Magic number for wharf signature files. (.pws)
    case signature
    /// Magic number for wharf manifest files. (.pwm)
    case manifest
    /// Magic number for wharf heal wounds files. (.pww)
    case wounds
    /// Magic number for wharf zip index files. (.pzi)
    case zip_index
}

let ModeMask = 0o644
let BlockSize: Int = 64 * 1024 // 64 KiB
