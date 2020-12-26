//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class ClipPreviewBaseViewController: UINavigationController {
    private weak var pageViewController: ClipPreviewPageViewController?

    override var prefersStatusBarHidden: Bool {
        return self.pageViewController?.prefersStatusBarHidden ?? true
    }

    // MARK: - Lifecycle

    init(pageViewController: ClipPreviewPageViewController) {
        self.pageViewController = pageViewController
        super.init(rootViewController: pageViewController)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Asset.Color.backgroundClient.color
    }
}

extension ClipPreviewBaseViewController: ClipPreviewPresentedAnimatorDataSource {
    // MARK: - ClipPreviewPresentedAnimatorDataSource

    func animatingPage(_ animator: ClipPreviewAnimator) -> ClipPreviewView? {
        self.view.layoutIfNeeded()
        return self.pageViewController?.currentViewController?.previewView
    }

    func currentIndex(_ animator: ClipPreviewAnimator) -> Int? {
        self.view.layoutIfNeeded()
        return self.pageViewController?.currentIndex
    }

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView) -> CGRect {
        self.view.layoutIfNeeded()
        guard let pageView = self.pageViewController?.currentViewController?.previewView else {
            return .zero
        }
        return pageView.convert(pageView.initialImageFrame, to: containerView)
    }
}

extension ClipPreviewBaseViewController: ClipInformationPresentingAnimatorDataSource {
    // MARK: - ClipInformationPresentingAnimatorDataSource

    func animatingPageView(_ animator: ClipInformationAnimator) -> ClipPreviewView? {
        self.view.layoutIfNeeded()
        return self.pageViewController?.currentViewController?.previewView
    }

    func presentingView(_ animator: ClipInformationAnimator) -> UIView? {
        return self.viewControllers.first?.view
    }

    func clipInformationAnimator(_ animator: ClipInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect {
        self.view.layoutIfNeeded()
        guard let pageView = self.pageViewController?.currentViewController?.previewView else {
            return .zero
        }
        return pageView.convert(pageView.initialImageFrame, to: containerView)
    }
}
