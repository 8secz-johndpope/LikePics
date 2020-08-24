//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipsListPreviewablePresenter: ClipsListDisplayablePresenter {
    var selectedClip: Clip? { get }

    var selectedIndex: Int? { get }

    func select(at index: Int) -> Clip?
}

extension ClipsListPreviewablePresenter {
    var selectedIndex: Int? {
        guard let clip = self.selectedClip else { return nil }
        return self.clips.firstIndex(where: { $0.url == clip.url })
    }
}
