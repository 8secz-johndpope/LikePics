//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

enum ThumbnailLayer {
    case primary
    case secondary
    case tertiary
}

protocol ClipsListDisplayablePresenter {
    var clips: [Clip] { get }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data?
}

extension ClipsListDisplayablePresenter where Self: ClipsListPresenter {
    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data? {
        let nullableClipItem: ClipItem? = {
            switch layer {
            case .primary:
                return clip.primaryItem
            case .secondary:
                return clip.secondaryItem
            case .tertiary:
                return clip.tertiaryItem
            }
        }()
        guard let clipItem = nullableClipItem else { return nil }

        switch self.storage.getImageData(ofUrl: clipItem.thumbnail.url, forClipUrl: clip.url) {
        case let .success(data):
            return data
        case let .failure(error):
            self.view?.showErrorMassage(Self.resolveErrorMessage(error))
            return nil
        }
    }
}
