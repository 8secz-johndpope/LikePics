//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Persistence
import TBoxCore

protocol ViewControllerFactory {
    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController
    func makeClipTargetCollectionViewController(url: URL, delegate: ClipTargetFinderDelegate) -> ClipTargetFinderViewController
}

class DependencyContainer {
    private lazy var clipsStorage = ClipStorage()
    private lazy var webImageResolver = WebImageResolver()
    private lazy var currentDateResolver = { Date() }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController {
        let presenter = ShareNavigationRootPresenter(storage: self.clipsStorage)
        return ShareNavigationRootViewController(factory: self, presenter: presenter)
    }

    func makeClipTargetCollectionViewController(url: URL, delegate: ClipTargetFinderDelegate) -> ClipTargetFinderViewController {
        let presenter = ClipTargetFinderPresenter(url: url,
                                                  storage: self.clipsStorage,
                                                  resolver: self.webImageResolver,
                                                  currentDateResovler: currentDateResolver)
        return ClipTargetFinderViewController(presenter: presenter, delegate: delegate)
    }
}
