//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipInformationPresentationAnimator: NSObject {
    private static let transitionDuration: TimeInterval = 0.2

    private weak var delegate: ClipInformationAnimatorDelegate?
    private let fallbackAnimator: FadeTransitionAnimatorProtocol

    // MARK: - Lifecycle

    init(delegate: ClipInformationAnimatorDelegate, fallbackAnimator: FadeTransitionAnimatorProtocol) {
        self.delegate = delegate
        self.fallbackAnimator = fallbackAnimator
    }
}

extension ClipInformationPresentationAnimator: ClipInformationAnimator {}

extension ClipInformationPresentationAnimator: UIViewControllerAnimatedTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Self.transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipInformationPresentingAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipInformationPresentedAnimatorDataSource & UIViewController),
            let targetInformationView = to.animatingInformationView(self),
            let selectedPage = from.animatingPageView(self),
            let selectedImageView = selectedPage.imageView,
            let selectedImage = selectedImageView.image,
            let fromViewBaseView = from.baseView(self)
        else {
            self.fallbackAnimator.startTransition(transitionContext, withDuration: Self.transitionDuration, isInteractive: false)
            return
        }

        /*
         アニメーション時、画像を Tab/Navigation Bar の裏側に回り込ませることで、自然なアニメーションを実現する
         このために、以下のような構成を取る

         ポイントは以下
         - ToViewはFromViewの裏に配置する
         - ToViewが見えるよう、FromViewの背景色をclearに設定する
         - containerViewの背景色は、ToViewの背景色と合わせておく

         +-+            +-+  +-+
         | |       +-+  | |  | |
         +-+       | |  | |  | |
          |        | |  | |  | |
          |        | |  | |  | |
          |        | |  | |  | |
          |        | |  | |  | |
          |        | |  | |  | |
          |   +-+  | |  | |  | |
          |   | |  +-+  | |  | |
          |   +-+   |   +-+  +-+
          |    |    |    |    |
          |    |    |    |    +--- ToView
          |    |    |    +-------- FromViewBaseView
          |    |    +------------- AnimatingImageView
          |    +------------------ ToolBAr
          +----------------------- NavigationBar
         |     |          |
         +--+--+          |
         |  |             |
         |  +--------------------- Components over base view
         |                |
         +---------+------+
                   |
                   +-------------- FromView
         */

        // HACK: Set new frame for updating the view to current orientation.
        to.view.frame = from.view.frame

        containerView.backgroundColor = to.view.backgroundColor
        containerView.insertSubview(to.view, belowSubview: from.view)

        let animatingImageView = UIImageView(image: selectedImage)
        animatingImageView.frame = from.clipInformationAnimator(self, imageFrameOnContainerView: containerView)

        // Preprocess

        let toViewBackgroundColor = to.view.backgroundColor

        targetInformationView.imageView.isHidden = true
        selectedImageView.isHidden = true
        from.view.backgroundColor = .clear

        fromViewBaseView.insertSubview(animatingImageView, aboveSubview: to.view)

        let postprocess = {
            targetInformationView.imageView.isHidden = false
            selectedImageView.isHidden = false
            from.view.backgroundColor = toViewBackgroundColor

            animatingImageView.removeFromSuperview()
        }

        to.view.alpha = 0

        CATransaction.begin()
        CATransaction.setAnimationDuration(self.transitionDuration(using: transitionContext))
        CATransaction.setCompletionBlock {
            postprocess()

            transitionContext.completeTransition(true)
        }

        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseInOut]
        ) {
            animatingImageView.frame = to.clipInformationAnimator(self, imageFrameOnContainerView: containerView)
            to.view.alpha = 1.0
        }

        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext) / 3,
            delay: 0,
            options: [.curveEaseIn]
        ) {
            from.componentsOverBaseView(self).forEach { $0.alpha = 0.0 }
        }

        CATransaction.commit()
    }

    func animationEnded(_ transitionCompleted: Bool) {
        self.delegate?.clipInformationAnimatorDelegate(self, didComplete: transitionCompleted)
    }
}
