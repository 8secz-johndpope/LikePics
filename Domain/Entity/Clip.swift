//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public struct Clip {
    public let url: URL
    public let webImages: [WebImage]

    // MARK: - Lifecycle

    public init(url: URL, webImages: [WebImage]) {
        self.url = url
        self.webImages = webImages
    }
}
