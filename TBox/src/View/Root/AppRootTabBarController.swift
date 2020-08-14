//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class AppRootTabBarController: UITabBarController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory

    init(factory: Factory) {
        self.factory = factory
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let clipViewController = factory.makeClipsViewController()

        clipViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .downloads, tag: 0)

        self.viewControllers = [
            clipViewController
        ]
    }
}

extension AppRootTabBarController: ClipPreviewPresentingAnimatorDataSource {
    // MARK: - ClipPreviewAnimatorDataSource

    func animatingCell(_ animator: ClipPreviewAnimator) -> ClipsCollectionViewCell? {
        guard let viewController = self.viewControllers?.compactMap({ $0 as? ClipsViewController }).first else {
            return nil
        }

        viewController.view.layoutIfNeeded()
        viewController.collectionView.layoutIfNeeded()

        guard let selectedIndexPath = viewController.selectedIndexPath else {
            return nil
        }

        if !viewController.collectionView.indexPathsForVisibleItems.contains(selectedIndexPath) {
            viewController.collectionView.scrollToItem(at: selectedIndexPath, at: .centeredVertically, animated: false)
            viewController.collectionView.reloadItems(at: viewController.collectionView.indexPathsForVisibleItems)
            viewController.collectionView.layoutIfNeeded()
        }

        guard let selectedCell = viewController.collectionView.cellForItem(at: selectedIndexPath) as? ClipsCollectionViewCell else {
            return nil
        }
        return selectedCell
    }
}
