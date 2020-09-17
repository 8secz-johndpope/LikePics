//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipsListProviding {
    var clips: [Clip] { get }
    var selectedClips: [Clip] { get }
    var selectedIndices: [Int] { get }
    var isEditing: Bool { get }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data?
    mutating func set(delegate: ClipsListProvidingDelegate)
    mutating func loadAll()
    mutating func setEditing(_ isEditing: Bool)
    mutating func select(at index: Int)
    mutating func deselect(at index: Int)
    mutating func deleteSelectedClips()
}
