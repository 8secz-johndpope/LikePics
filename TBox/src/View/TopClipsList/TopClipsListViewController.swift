//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class TopClipsListViewController: UIViewController, ClipsListDisplayable {
    typealias Factory = ViewControllerFactory
    typealias Presenter = TopClipsListPresenterProxy

    let factory: Factory
    var presenter: Presenter
    let transitionController: ClipPreviewTransitionControllerProtocol
    var selectedIndexPath: IndexPath?

    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var collectionView: ClipsCollectionView!

    var clips: [Clip] {
        self.presenter.clips
    }

    // MARK: - Lifecycle

    init(factory: Factory, presenter: TopClipsListPresenterProxy, transitionController: ClipPreviewTransitionControllerProtocol) {
        self.factory = factory
        self.presenter = presenter
        self.transitionController = transitionController
        super.init(nibName: nil, bundle: nil)

        self.addBecomeActiveNotification()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.removeBecomeActiveNotification()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let layout = self.collectionView?.collectionViewLayout as? ClipCollectionLayout {
            layout.delegate = self
        }

        self.presenter.set(view: self)
        self.presenter.reload()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presenter.reload()
    }

    // MARK: - Methods

    // MARK: Notification

    private func addBecomeActiveNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    private func removeBecomeActiveNotification() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
    }

    @objc func didBecomeActive() {
        self.presenter.reload()
    }
}

extension TopClipsListViewController: TopClipsListViewProtocol {
    // MARK: - TopClipsListViewProtocol

    func startLoading() {
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }

    func endLoading() {
        self.indicator.isHidden = true
        self.indicator.stopAnimating()
    }

    func showErrorMassage(_ message: String) {
        let alert = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
    }

    func reload() {
        self.collectionView.reloadData()
    }
}

extension TopClipsListViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return self.collectionView(self, collectionView, shouldSelectItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return self.collectionView(self, collectionView, shouldSelectItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.collectionView(self, collectionView, didSelectItemAt: indexPath)
    }
}

extension TopClipsListViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.numberOfSections(self, in: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.collectionView(self, collectionView, numberOfItemsInSection: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return self.collectionView(self, collectionView, cellForItemAt: indexPath)
    }
}

extension TopClipsListViewController: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsCollectionLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        return self.collectionView(self, collectionView, photoHeightForWidth: width, atIndexPath: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat {
        return self.collectionView(self, collectionView, heightForHeaderAtIndexPath: indexPath)
    }
}

extension TopClipsListViewController: ClipsPresentingViewController {}
