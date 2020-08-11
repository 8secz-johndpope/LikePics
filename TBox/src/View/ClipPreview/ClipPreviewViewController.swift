//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class ClipPreviewViewController: UIPageViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: ClipPreviewPresenter
    private let transitionController: ClipPreviewTransitionControllerProtocol

    private var nextIndex: Int?
    private var currentIndex: Int = 0

    // MARK: - Lifecycle

    init(factory: Factory, presenter: ClipPreviewPresenter, transitionController: ClipPreviewTransitionControllerProtocol) {
        self.factory = factory
        self.presenter = presenter
        self.transitionController = transitionController
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [
            UIPageViewController.OptionsKey.interPageSpacing: 40
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupNavigationBar()

        if let webImage = self.presenter.clip.webImages.first {
            let viewController = self.factory.makeClipPreviewPageViewController(webImage: webImage)
            self.setViewControllers([viewController], direction: .forward, animated: true, completion: nil)
        }

        self.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateNavigationBarAppearance()
    }

    // MARK: - Methods

    private func updateNavigationBarAppearance() {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private func setupNavigationBar() {
        self.navigationItem.title = ""

        self.navigationItem.backBarButtonItem = .init(title: nil,
                                                      style: .plain,
                                                      target: nil,
                                                      action: nil)

        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(self.didTapInfoButton), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = .init(customView: infoButton)
    }

    @objc func didTapInfoButton() {
        print(#function)
    }

    private func resolveIndex(of viewController: UIViewController) -> Int? {
        guard let viewController = viewController as? ClipPreviewPageViewController else { return nil }
        guard let currentIndex = self.presenter.clip.webImages.firstIndex(where: { $0.url == viewController.presentingImageUrl }) else { return nil }
        return currentIndex
    }

    private func makeViewController(at index: Int) -> UIViewController? {
        guard self.presenter.clip.webImages.indices.contains(index) else { return nil }
        return self.factory.makeClipPreviewPageViewController(webImage: self.presenter.clip.webImages[index])
    }
}

extension ClipPreviewViewController: UIPageViewControllerDelegate {
    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let nextViewController = pendingViewControllers.first, let nextIndex = self.resolveIndex(of: nextViewController) else {
            fatalError("Unexpected view controller detected.")
        }
        self.nextIndex = nextIndex
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let nextIndex = self.nextIndex, completed {
            self.currentIndex = nextIndex
        }
        self.nextIndex = nil
    }
}

extension ClipPreviewViewController: UIPageViewControllerDataSource {
    // MARK: - UIPageViewControllerDataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = self.resolveIndex(of: viewController), currentIndex > 0 else { return nil }
        return self.makeViewController(at: currentIndex - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = self.resolveIndex(of: viewController), currentIndex < self.presenter.clip.webImages.count else { return nil }
        return self.makeViewController(at: currentIndex + 1)
    }
}

extension ClipPreviewViewController: ClipPreviewPresentedViewControllerProtocol {
    // MARK: - ClipPreviewPresentedViewControllerProtocol

    func pageView(_ animator: UIViewControllerAnimatedTransitioning) -> ClipPreviewPageView {
        let currentViewController = self.viewControllers?
            .compactMap { $0 as? ClipPreviewPageViewController }
            .first(where: { $0.presentingImageUrl == self.presenter.clip.webImages[self.currentIndex].url })
        guard let viewController = currentViewController, let pageView = viewController.pageView else {
            fatalError("Unexpected view controller presented.")
        }
        return pageView
    }
}
