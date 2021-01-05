//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

// sourcery: AutoDefaultValue
public struct ImageSize: Equatable {
    public static let zero = ImageSize(height: 0, width: 0)

    public let height: Double
    public let width: Double

    public var cgSize: CGSize {
        return CGSize(width: self.width,
                      height: self.height)
    }

    // MARK: - Lifecycle

    public init(height: Double, width: Double) {
        self.height = height
        self.width = width
    }
}
