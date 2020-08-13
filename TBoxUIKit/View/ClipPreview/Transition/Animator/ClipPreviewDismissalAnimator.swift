//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipPreviewDismissalAnimator: NSObject {}

extension ClipPreviewDismissalAnimator: ClipPreviewAnimator {}

extension ClipPreviewDismissalAnimator: UIViewControllerAnimatedTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipPreviewPresentedAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipPreviewPresentingAnimatorDataSource & UIViewController),
            let visiblePage = from.animatingPage(self),
            let visibleImageView = visiblePage.imageView,
            let visibleImage = visibleImageView.image,
            let targetCell = to.animatingCell(self)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let animatingImageView = UIImageView(image: visibleImage)
        animatingImageView.contentMode = .scaleAspectFit
        animatingImageView.frame = visiblePage.scrollView.convert(visiblePage.imageView.frame, to: containerView)
        containerView.addSubview(animatingImageView)

        targetCell.isHidden = true
        visibleImageView.isHidden = true

        containerView.insertSubview(to.view, aboveSubview: from.view)

        to.view.alpha = 0
        from.navigationController?.navigationBar.alpha = 1.0

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            ClipsCollectionViewCell.setupAppearance(imageView: visibleImageView)

            animatingImageView.frame = targetCell.primaryImageView.convert(targetCell.primaryImageView.frame, to: containerView)

            to.view.alpha = 1.0
            from.view.alpha = 0
            from.navigationController?.navigationBar.alpha = 0
        }, completion: { finished in
            visibleImageView.isHidden = false
            targetCell.isHidden = false
            animatingImageView.removeFromSuperview()
            transitionContext.completeTransition(true)
        })
    }
}
