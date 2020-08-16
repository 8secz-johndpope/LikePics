//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipPreviewInteractiveDismissalAnimator: NSObject {
    struct InnerContext {
        let transitionContext: UIViewControllerContextTransitioning
        let initialImageFrame: CGRect
        let animatingView: UIView
        let animatingImageView: UIImageView
    }

    private static let startingImageScale: CGFloat = 1.0
    private static let finalImageScale: CGFloat = 0.5

    private static let startingAlpha: CGFloat = 1.0
    private static let finalAlpha: CGFloat = 0

    private static let startingCornerRadius: CGFloat = 0
    private static let finalCornerRadius: CGFloat = 10

    private static let cancelAnimateDuration: Double = 0.5
    private static let endAnimateDuration: Double = 0.25

    private var innerContext: InnerContext?

    // MARK: - Methods

    func didPan(sender: UIPanGestureRecognizer) {
        guard let innerContext = self.innerContext else { return }
        let transitionContext = innerContext.transitionContext
        let containerView = transitionContext.containerView
        let initialImageFrame = innerContext.initialImageFrame
        let animatingView = innerContext.animatingView
        let animatingImageView = innerContext.animatingImageView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipPreviewPresentedAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipPreviewPresentingAnimatorDataSource & UIViewController),
            let fromPage = from.animatingPage(self),
            let fromIndex = from.currentIndex(self),
            let fromImageView = fromPage.imageView,
            let toCell = to.animatingCell(self)
        else {
            innerContext.transitionContext.completeTransition(false)
            return
        }

        // Calculation

        let finalImageFrame = to.clipPreviewAnimator(self, frameOnContainerView: containerView, forIndex: fromIndex)
        let translation = sender.translation(in: from.view)
        let verticalDelta = translation.y < 0 ? 0 : translation.y
        let scale = Self.calcScale(in: from.view, verticalDelta: verticalDelta)
        let cornerRadius = Self.calcCornerRadius(in: from.view, verticalDelta: verticalDelta)

        // Middle Animation

        toCell.isHidden = true
        fromImageView.isHidden = true

        to.view.alpha = 1
        from.view.alpha = Self.calcAlpha(in: from.view, verticalDelta: verticalDelta)

        animatingView.transform = CGAffineTransform(scaleX: scale, y: scale)
        let initialAnchorPoint = CGPoint(x: initialImageFrame.midX, y: initialImageFrame.midY)
        let nextAnchorPoint = CGPoint(x: initialAnchorPoint.x + translation.x,
                                      y: initialAnchorPoint.y + translation.y - ((1 - scale) * initialImageFrame.height / 2))
        animatingView.center = nextAnchorPoint
        animatingImageView.frame = animatingView.bounds
        animatingView.layer.cornerRadius = cornerRadius
        animatingImageView.layer.cornerRadius = cornerRadius

        transitionContext.updateInteractiveTransition(1 - scale)

        // End Animation

        if sender.state == .ended {
            let velocity = sender.velocity(in: from.view)
            let scrollToUp = velocity.y < 0
            let releaseAboveInitialPosition = nextAnchorPoint.y < initialAnchorPoint.y
            if scrollToUp || releaseAboveInitialPosition {
                self.startCancelAnimation(hideViews: [to.view], presentViews: [from.view], hiddenViews: [toCell, fromImageView], currentCornerRadius: cornerRadius, innerContext: innerContext)
            } else {
                self.startEndAnimation(finalImageFrame: finalImageFrame, hideViews: [from.view], presentViews: [to.view], hiddenViews: [toCell, fromImageView], currentCornerRadius: cornerRadius, innerContext: innerContext)
            }
        }
    }

    // MARK: Animation

    private func startCancelAnimation(hideViews: [UIView?], presentViews: [UIView?], hiddenViews: [UIView], currentCornerRadius: CGFloat, innerContext: InnerContext) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.cancelAnimateDuration)
        CATransaction.setCompletionBlock {
            hiddenViews.forEach { $0.isHidden = false }
            innerContext.animatingView.removeFromSuperview()
            innerContext.transitionContext.cancelInteractiveTransition()
            innerContext.transitionContext.completeTransition(!innerContext.transitionContext.transitionWasCancelled)
            self.innerContext = nil
        }

        let cornerAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
        cornerAnimation.fromValue = currentCornerRadius
        cornerAnimation.toValue = 0
        innerContext.animatingView.layer.cornerRadius = 0
        innerContext.animatingView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))
        innerContext.animatingImageView.layer.cornerRadius = 0
        innerContext.animatingImageView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))

        UIView.animate(
            withDuration: Self.cancelAnimateDuration,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0,
            options: [],
            animations: {
                innerContext.animatingView.frame = innerContext.initialImageFrame
                innerContext.animatingImageView.frame = innerContext.animatingView.bounds
                hideViews.forEach { $0?.alpha = 0 }
                presentViews.forEach { $0?.alpha = 1 }
            }
        )

        CATransaction.commit()
    }

    private func startEndAnimation(finalImageFrame: CGRect, hideViews: [UIView?], presentViews: [UIView?], hiddenViews: [UIView], currentCornerRadius: CGFloat, innerContext: InnerContext) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.endAnimateDuration)
        CATransaction.setCompletionBlock {
            hiddenViews.forEach { $0.isHidden = false }
            innerContext.animatingView.removeFromSuperview()
            innerContext.transitionContext.completeTransition(!innerContext.transitionContext.transitionWasCancelled)
            self.innerContext = nil
        }

        let cornerAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
        cornerAnimation.fromValue = currentCornerRadius
        cornerAnimation.toValue = ClipsCollectionViewCell.cornerRadius
        innerContext.animatingView.layer.cornerRadius = ClipsCollectionViewCell.cornerRadius
        innerContext.animatingView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))
        innerContext.animatingImageView.layer.cornerRadius = ClipsCollectionViewCell.cornerRadius
        innerContext.animatingImageView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))

        UIView.animate(
            withDuration: Self.endAnimateDuration,
            delay: 0,
            options: [],
            animations: {
                innerContext.animatingView.frame = finalImageFrame
                innerContext.animatingImageView.frame = innerContext.animatingView.bounds
                hideViews.forEach { $0?.alpha = 0 }
                presentViews.forEach { $0?.alpha = 1 }
            }
        )

        CATransaction.commit()
    }

    // MARK: Calculation

    private static func calcScale(in view: UIView, verticalDelta: CGFloat) -> CGFloat {
        let maximumDelta = view.bounds.height * 2 / 3
        let percentScale = min(abs(verticalDelta) / maximumDelta, 1.0)
        let scaleRange = Self.startingImageScale - Self.finalImageScale
        return Self.startingImageScale - (percentScale * scaleRange)
    }

    private static func calcAlpha(in view: UIView, verticalDelta: CGFloat) -> CGFloat {
        let maximumDelta = view.bounds.height * 2 / 3
        let percentAlpha = min(abs(verticalDelta) / maximumDelta, 1.0)
        let alphaRange = Self.startingAlpha - Self.finalAlpha
        return Self.startingAlpha - (percentAlpha * alphaRange)
    }

    private static func calcCornerRadius(in view: UIView, verticalDelta: CGFloat) -> CGFloat {
        let maximumDelta = view.bounds.height / 2
        let percentCornerRadius = min(abs(verticalDelta) / maximumDelta, 1.0)
        let cornerRadiusRange = Self.startingCornerRadius - Self.finalCornerRadius
        return Self.startingCornerRadius - (percentCornerRadius * cornerRadiusRange)
    }
}

extension ClipPreviewInteractiveDismissalAnimator: ClipPreviewAnimator {}

extension ClipPreviewInteractiveDismissalAnimator: UIViewControllerInteractiveTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipPreviewPresentedAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipPreviewPresentingAnimatorDataSource & UIViewController),
            let fromPage = from.animatingPage(self),
            let fromImageView = fromPage.imageView,
            let fromImage = fromImageView.image,
            let toCell = to.animatingCell(self)
        else {
            transitionContext.completeTransition(false)
            return
        }

        containerView.backgroundColor = .clear
        containerView.insertSubview(to.view, belowSubview: from.view)

        let initialImageFrame = from.clipPreviewAnimator(self, frameOnContainerView: containerView)

        let animatingView = UIView()
        ClipsCollectionViewCell.setupAppearance(shadowView: animatingView, interfaceStyle: from.traitCollection.userInterfaceStyle)
        animatingView.frame = initialImageFrame
        animatingView.backgroundColor = .red
        containerView.addSubview(animatingView)

        let animatingImageView = UIImageView(image: fromImage)
        ClipsCollectionViewCell.setupAppearance(imageView: animatingImageView)
        animatingImageView.frame = animatingView.bounds
        animatingView.addSubview(animatingImageView)

        toCell.isHidden = true
        fromImageView.isHidden = true

        self.innerContext = .init(
            transitionContext: transitionContext,
            initialImageFrame: initialImageFrame,
            animatingView: animatingView,
            animatingImageView: animatingImageView
        )
    }
}
