//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class ClipPreviewTabBarController: UITabBarController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let previewViewController: ClipPreviewViewController

    // MARK: - Lifecycle

    init(factory: Factory, viewController: ClipPreviewViewController) {
        self.factory = factory
        self.previewViewController = viewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewControllers = [
            UINavigationController(rootViewController: self.previewViewController)
        ]
    }
}

extension ClipPreviewTabBarController: ClipPreviewPresentedAnimatorDataSource {
    // MARK: - ClipPreviewPresentedAnimatorDataSource

    func animatingPage(_ animator: ClipPreviewAnimator) -> ClipPreviewPageView? {
        self.view.layoutIfNeeded()
        return self.previewViewController.currentViewController?.pageView
    }

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView) -> CGRect {
        self.view.layoutIfNeeded()
        guard let pageView = self.previewViewController.currentViewController?.pageView else {
            return .zero
        }
        return pageView.convert(pageView.imageViewFrame, to: containerView)
    }
}
