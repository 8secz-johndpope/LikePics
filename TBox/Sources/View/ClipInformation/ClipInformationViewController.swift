//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit
import UIKit

class ClipInformationViewController: UIViewController {
    typealias Factory = ViewControllerFactory
    typealias Dependency = ClipInformationViewModelType

    private let factory: Factory
    private let viewModel: Dependency
    private let transitioningController: ClipInformationTransitioningControllerProtocol
    private lazy var editSiteUrlAlertContainer = TextEditAlert(
        configuration: .init(title: L10n.clipPreviewViewAlertForEditSiteUrlTitle,
                             message: L10n.clipPreviewViewAlertForEditSiteUrlMessage,
                             placeholder: L10n.clipPreviewViewAlertForEditSiteUrlPlaceholder)
    )

    private weak var dataSource: ClipInformationViewDataSource?
    private var shouldHideStatusBar: Bool = false

    private var panGestureRecognizer: UIPanGestureRecognizer!

    override var prefersStatusBarHidden: Bool {
        return self.shouldHideStatusBar
    }

    private var subscriptions = Set<AnyCancellable>()

    private let informationView: ClipInformationView

    // MARK: - Lifecycle

    init(factory: Factory,
         dataSource: ClipInformationViewDataSource,
         viewModel: Dependency,
         informationView: ClipInformationView,
         transitioningController: ClipInformationTransitioningControllerProtocol)
    {
        self.factory = factory
        self.viewModel = viewModel
        self.informationView = informationView
        self.transitioningController = transitioningController
        self.dataSource = dataSource

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        informationView.alpha = 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupAppearance()
        self.setupInformationView()
        self.setupGestureRecognizer()

        self.informationView.delegate = self
        self.informationView.dataSource = self.dataSource

        self.bind(to: viewModel)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.shouldHideStatusBar = true
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.shouldHideStatusBar = false
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { _ in
            self.informationView.updateImageViewFrame(for: size)
        } completion: { _ in
            // NOP
        }
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.view.backgroundColor = Asset.Color.backgroundClient.color
        self.modalTransitionStyle = .crossDissolve
    }

    private func setupInformationView() {
        self.view.addSubview(self.informationView)
        NSLayoutConstraint.activate([
            self.informationView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.informationView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.informationView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.informationView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        // HACK: Interactiveな画面遷移時に引っ掛かりが生じるため、初回時のみアニメーションをオフにする
        dependency.outputs.info
            .prefix(1)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                self?.informationView.setInfo(info, animated: false)
            }
            .store(in: &self.subscriptions)

        dependency.outputs.info
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                self?.informationView.setInfo(info, animated: true)
            }
            .store(in: &self.subscriptions)

        dependency.outputs.close
            .sink { [weak self] _ in self?.dismiss(animated: true, completion: nil) }
            .store(in: &self.subscriptions)

        dependency.outputs.errorMessage
            .sink { [weak self] message in
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.subscriptions)
    }

    // MARK: Gesture Recognizer

    private func setupGestureRecognizer() {
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.didPan(_:)))
        self.panGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(self.panGestureRecognizer)
    }

    @objc
    func didPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            self.informationView.isScrollEnabled = false
            self.transitioningController.beginTransition(.custom(interactive: true))
            self.dismiss(animated: true, completion: nil)

        case .ended:
            self.informationView.isScrollEnabled = true
            if self.transitioningController.isInteractive {
                self.transitioningController.didPanForDismissal(sender: sender)
            }

        default:
            if self.transitioningController.isInteractive {
                self.transitioningController.didPanForDismissal(sender: sender)
            }
        }
    }
}

extension ClipInformationViewController: ClipInformationViewDelegate {
    // MARK: - ClipInformationViewDelegate

    func didTapAddTagButton(_ view: ClipInformationView) {
        let tags = self.viewModel.outputs.tagIdsValue
        let nullableViewController = self.factory.makeTagSelectionViewController(selectedTags: tags, context: nil, delegate: self)
        guard let viewController = nullableViewController else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func clipInformationView(_ view: ClipInformationView, didSelectTag tag: Tag, at placement: UIView) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipInformationViewAlertForDeleteTagMessage,
                                      preferredStyle: .actionSheet)

        let title = L10n.clipInformationViewAlertForDeleteTagAction
        alert.addAction(.init(title: title, style: .destructive, handler: { [weak self] _ in
            self?.viewModel.inputs.removeTagFromClip(tag)
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.sourceView = placement

        self.present(alert, animated: true, completion: nil)
    }

    func clipInformationView(_ view: ClipInformationView, shouldOpen url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func clipInformationView(_ view: ClipInformationView, shouldCopy url: URL) {
        UIPasteboard.general.string = url.absoluteString
    }

    func clipInformationView(_ view: ClipInformationView, shouldHide isHidden: Bool) {
        self.viewModel.inputs.update(isHidden: isHidden)
    }

    func clipInformationView(_ view: ClipInformationView, startEditingSiteUrl url: URL?) {
        self.editSiteUrlAlertContainer.present(withText: url?.absoluteString, on: self) {
            guard let text = $0 else { return true }
            return text.isEmpty || URL(string: text) != nil
        } completion: { [weak self] action in
            guard case let .saved(text: text) = action else { return }
            self?.viewModel.inputs.update(siteUrl: URL(string: text))
        }
    }
}

extension ClipInformationViewController: TagSelectionDelegate {
    // MARK: - TagSelectionDelegate

    func tagSelection(_ sender: AnyObject, didSelectTags tags: [Tag], withContext context: Any?) {
        let tagIds = Set(tags.map { $0.id })
        self.viewModel.inputs.replaceTagsOfClip(tagIds)
    }
}

extension ClipInformationViewController: UIGestureRecognizerDelegate {
    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer, gestureRecognizer === self.panGestureRecognizer {
            guard gestureRecognizer.velocity(in: self.view).y > 0 else { return false }
            return true
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer == self.informationView.panGestureRecognizer {
            return self.informationView.contentOffSet.y <= 0
        }
        return false
    }
}

extension ClipInformationViewController: ClipInformationPresentedAnimatorDataSource {
    // MARK: - ClipInformationPresentedAnimatorDataSource

    func animatingInformationView(_ animator: ClipInformationAnimator) -> ClipInformationView? {
        return self.informationView
    }

    func clipInformationAnimator(_ animator: ClipInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect {
        // HACK: Update safeAreaInsets immediately.
        containerView.layoutIfNeeded()
        return self.informationView.convert(self.informationView.calcInitialFrame(), to: containerView)
    }
}
