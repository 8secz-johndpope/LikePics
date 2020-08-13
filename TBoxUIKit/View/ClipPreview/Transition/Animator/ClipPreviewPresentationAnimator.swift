//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipPreviewPresentationAnimator: NSObject {}

extension ClipPreviewPresentationAnimator: ClipPreviewAnimator {}

extension ClipPreviewPresentationAnimator: UIViewControllerAnimatedTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipPreviewPresentingAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipPreviewPresentedAnimatorDataSource & UIViewController),
            let targetImageView = to.animatingPage(self),
            let selectedCell = from.animatingCell(self),
            let selectedImageView = selectedCell.primaryImageView,
            let selectedImage = selectedImageView.image
        else {
            transitionContext.completeTransition(false)
            return
        }

        let animatingImageView = UIImageView(image: selectedImage)
        ClipsCollectionViewCell.setupAppearance(imageView: animatingImageView)
        animatingImageView.frame = selectedCell.convert(selectedImageView.frame, to: from.view)
        containerView.addSubview(animatingImageView)

        targetImageView.isHidden = true
        selectedImageView.isHidden = true

        containerView.insertSubview(to.view, belowSubview: from.view)

        to.view.alpha = 0

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            ClipsCollectionViewCell.resetAppearance(imageView: animatingImageView)

            let cellDisplayedArea = to.view.frame.inset(by: to.view.safeAreaInsets)
            let frameOnCell = ClipPreviewPageView.calcCenterizedFrame(ofImage: selectedImage, in: cellDisplayedArea)
            animatingImageView.frame = .init(origin: to.view.convert(frameOnCell.origin, to: containerView),
                                             size: frameOnCell.size)
            animatingImageView.layer.cornerRadius = 0

            from.view.alpha = 0
            to.view.alpha = 1.0
        }, completion: { finished in
            targetImageView.isHidden = false
            selectedImageView.isHidden = false
            animatingImageView.removeFromSuperview()
            transitionContext.completeTransition(true)
        })
    }
}
