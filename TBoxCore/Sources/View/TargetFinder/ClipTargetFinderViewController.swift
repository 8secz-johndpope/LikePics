//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import TBoxUIKit
import UIKit

public protocol ClipTargetFinderDelegate: AnyObject {
    func didCancel(_ viewController: ClipTargetFinderViewController)

    func didFinish(_ viewController: ClipTargetFinderViewController)
}

protocol SelectableImageCellDataSource {
    var url: URL { get }
    var height: CGFloat { get }
    var width: CGFloat { get }
}

public class ClipTargetFinderViewController: UIViewController {
    private let presenter: ClipTargetFinderPresenter
    private let emptyMessageView = EmptyMessageView()

    private lazy var itemDone = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveAction))
    private lazy var itemReload = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(reloadAction))

    private weak var delegate: ClipTargetFinderDelegate?
    private var cancellableBag = Set<AnyCancellable>()

    @IBOutlet var collectionView: ClipSelectionCollectionView!
    @IBOutlet var indicator: UIActivityIndicatorView!

    // MARK: - Lifecycle

    public init(presenter: ClipTargetFinderPresenter, delegate: ClipTargetFinderDelegate) {
        self.presenter = presenter
        self.delegate = delegate
        super.init(nibName: "ClipTargetFinderViewController", bundle: Bundle(for: Self.self))

        self.presenter.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    // MARK: Downsampling

    private static func calcScale(forSize source: CGSize, toFit destination: CGSize) -> CGFloat {
        let widthScale = destination.width / source.width
        let heightScale = destination.height / source.height
        return min(widthScale, heightScale)
    }

    private static func calcDownsamplingSize(forOriginalSize imageSize: CGSize) -> CGSize {
        let screenSize = UIScreen.main.bounds.size
        let rotatedScreenSize = CGSize(width: UIScreen.main.bounds.size.height,
                                       height: UIScreen.main.bounds.size.width)

        let scaleToFitScreen = max(self.calcScale(forSize: imageSize, toFit: screenSize),
                                   self.calcScale(forSize: imageSize, toFit: rotatedScreenSize))
        let targetScale = min(1, scaleToFitScreen)

        return imageSize.scaled(by: targetScale)
    }

    private static func downsampledImage(data: Data, to pointSize: CGSize) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }

        let maxDimensionInPixels = max(pointSize.width, pointSize.height)
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }

        return UIImage(cgImage: downsampledImage)
    }

    // MARK: Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.presenter.attachWebView(to: self.view)

        if let layout = self.collectionView?.collectionViewLayout as? ClipCollectionLayout {
            layout.delegate = self
        }

        self.setupNavigationBar()
        self.setupEmptyMessage()

        self.presenter.findImages()
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
        self.navigationItem.title = L10n.clipTargetFinderViewTitle

        [self.itemReload, self.itemDone].forEach {
            $0.setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .disabled)
            $0.isEnabled = false
        }

        self.navigationItem.setLeftBarButton(self.itemReload, animated: true)
        self.navigationItem.setRightBarButton(self.itemDone, animated: true)
    }

    @objc
    private func saveAction() {
        self.presenter.saveSelectedImages()
    }

    @objc
    private func reloadAction() {
        self.presenter.findImages()
    }

    // MARK: EmptyMessage

    private func setupEmptyMessage() {
        self.view.addSubview(self.emptyMessageView)
        self.emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        self.emptyMessageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        self.emptyMessageView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        self.emptyMessageView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        self.emptyMessageView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true

        self.emptyMessageView.title = L10n.clipTargetFinderViewEmptyTitle
        self.emptyMessageView.message = L10n.clipTargetFinderViewEmptyMessage
        self.emptyMessageView.actionButtonTitle = L10n.clipTargetFinderViewEmptyActionTitle
        self.emptyMessageView.delegate = self

        self.emptyMessageView.alpha = 0
    }
}

extension ClipTargetFinderViewController: ClipTargetFinderViewProtocol {
    // MARK: - ClipTargetFinderViewProtocol

    func startLoading() {
        self.emptyMessageView.alpha = 0
        self.indicator.startAnimating()
        self.indicator.isHidden = false
        self.itemReload.isEnabled = false
    }

    func endLoading() {
        self.indicator.isHidden = true
        self.indicator.stopAnimating()
        self.itemReload.isEnabled = true
    }

    func reloadList() {
        if self.presenter.selectableImages.isEmpty {
            self.collectionView.isHidden = true
            self.emptyMessageView.alpha = 1
        } else {
            self.collectionView.isHidden = false
            self.emptyMessageView.alpha = 0
        }
        self.collectionView.reloadData()
    }

    func showConfirmationForOverwrite() {
        let alert = UIAlertController(title: "",
                                      message: L10n.clipTargetFinderViewOverwriteAlertBody,
                                      preferredStyle: .alert)

        alert.addAction(
            .init(title: L10n.clipTargetFinderViewOverwriteAlertCancel,
                  style: .cancel,
                  handler: { [weak self] _ in
                      guard let self = self else { return }
                      self.delegate?.didCancel(self)
                  })
        )

        alert.addAction(
            .init(title: L10n.clipTargetFinderViewOverwriteAlertOk,
                  style: .default,
                  handler: { [weak self] _ in
                      self?.presenter.enableOverwrite()
                      self?.presenter.findImages()
                  })
        )

        self.present(alert, animated: true, completion: nil)
    }

    func show(errorMessage: String) {
        let alert = UIAlertController(title: L10n.clipTargetFinderViewErrorAlertTitle,
                                      message: errorMessage,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: L10n.clipTargetFinderViewErrorAlertOk,
                              style: .default,
                              handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func updateSelectionOrder(at index: Int, to order: Int) {
        guard let cell = self.collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? ClipSelectionCollectionViewCell else { return }
        cell.selectionOrder = order
    }

    func updateDoneButton(isEnabled: Bool) {
        self.itemDone.isEnabled = isEnabled
    }

    func resetSelection() {
        self.collectionView.indexPathsForSelectedItems?
            .forEach { self.collectionView.deselectItem(at: $0, animated: false) }
        self.collectionView.visibleCells
            .compactMap { $0 as? ClipSelectionCollectionViewCell }
            .forEach { $0.selectionOrder = nil }
    }

    func notifySavedImagesSuccessfully() {
        self.delegate?.didFinish(self)
    }
}

extension ClipTargetFinderViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return self.presenter.selectableImages.indices.contains(indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return self.presenter.selectableImages.indices.contains(indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return self.presenter.selectableImages.indices.contains(indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.presenter.selectItem(at: indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.presenter.deselectItem(at: indexPath.row)
    }
}

extension ClipTargetFinderViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.presenter.selectableImages.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: type(of: self.collectionView).cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? ClipSelectionCollectionViewCell else { return dequeuedCell }
        guard self.presenter.selectableImages.indices.contains(indexPath.row) else { return cell }

        let meta = self.presenter.selectableImages[indexPath.row]
        cell.url = meta.url

        URLSession.shared
            .dataTaskPublisher(for: self.presenter.selectableImages[indexPath.row].url)
            .map { data, _ -> UIImage? in
                let downsampleSize = Self.calcDownsamplingSize(forOriginalSize: CGSize(width: meta.width, height: meta.height))
                return Self.downsampledImage(data: data, to: downsampleSize)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in
                // NOP
            }, receiveValue: { image in
                guard cell.url == meta.url else { return }
                cell.image = image
            })
            .store(in: &self.cancellableBag)

        if let indexInSelection = self.presenter.selectedIndices.firstIndex(of: indexPath.row) {
            cell.selectionOrder = indexInSelection + 1
        }

        return cell
    }
}

extension ClipTargetFinderViewController: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsCollectionLayoutDelegate

    public func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        guard self.presenter.selectableImages.indices.contains(indexPath.row) else { return .zero }
        let imageHeight = self.presenter.selectableImages[indexPath.row].height
        let imageWidth = self.presenter.selectableImages[indexPath.row].width
        return width * CGFloat(imageHeight / imageWidth)
    }

    public func collectionView(_ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat {
        return .zero
    }
}

extension ClipTargetFinderViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    public func didTapActionButton(_ view: EmptyMessageView) {
        self.presenter.findImages()
    }
}

private extension CGSize {
    func scaled(by scale: CGFloat) -> Self {
        return .init(width: self.width * scale, height: self.height * scale)
    }
}
