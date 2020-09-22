//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit
import WebKit

public protocol ClipInformationViewDataSource: AnyObject {
    func previewImage(_ view: ClipInformationView) -> UIImage?
    func previewPageBounds(_ view: ClipInformationView) -> CGRect
}

public protocol ClipInformationViewDelegate: AnyObject {
    func clipInformationView(_ view: ClipInformationView, didSelectTag name: String)
    func clipInformationView(_ view: ClipInformationView, shouldOpen url: URL)
    func clipInformationView(_ view: ClipInformationView, shouldCopy url: URL)
}

public class ClipInformationView: UIView {
    public var tags: [String] = [] {
        didSet {
            self.tagCollectionView.reloadData()
        }
    }

    public var siteUrl: String? {
        get {
            return self.siteUrlButton.titleLabel?.text
        }
        set {
            self.siteUrlButton.setTitle(newValue, for: .normal)
        }
    }

    public var imageUrl: String? {
        get {
            return self.imageUrlButton.titleLabel?.text
        }
        set {
            self.imageUrlButton.setTitle(newValue, for: .normal)
        }
    }

    public var panGestureRecognizer: UIPanGestureRecognizer {
        self.scrollView.panGestureRecognizer
    }

    public var contentOffSet: CGPoint {
        self.scrollView.contentOffset
    }

    public var isScrollEnabled: Bool {
        get {
            return self.scrollView.isScrollEnabled
        }
        set {
            self.scrollView.isScrollEnabled = newValue
        }
    }

    public weak var delegate: ClipInformationViewDelegate?

    public weak var dataSource: ClipInformationViewDataSource? {
        didSet {
            self.imageView.image = self.dataSource?.previewImage(self)
            self.updateImageViewFrame()
        }
    }

    // swiftlint:disable implicitly_unwrapped_optional superfluous_disable_command
    var imageView: UIImageView!
    // swiftlint:enable implicitly_unwrapped_optional superfluous_disable_command

    @IBOutlet var baseView: UIView!
    @IBOutlet var tagCollectionView: TagCollectionView!
    @IBOutlet var siteUrlButton: UIButton!
    @IBOutlet var imageUrlButton: UIButton!
    @IBOutlet var siteUrlTitleLabel: UILabel!
    @IBOutlet var imageUrlTitleLabel: UILabel!
    @IBOutlet var scrollView: UIScrollView!

    // MARK: - Lifecycle

    override public init(frame: CGRect) {
        super.init(frame: frame)

        self.setupFromNib()
        self.setupAppearance()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.setupFromNib()
        self.setupAppearance()
    }

    @IBAction func didTapSiteUrl(_ sender: UIButton) {
        guard let text = sender.titleLabel?.text, let url = URL(string: text) else { return }
        self.delegate?.clipInformationView(self, shouldOpen: url)
    }

    @IBAction func didTapImageUrl(_ sender: UIButton) {
        guard let text = sender.titleLabel?.text, let url = URL(string: text) else { return }
        self.delegate?.clipInformationView(self, shouldOpen: url)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        self.updateImageViewFrame()
    }

    // MARK: - Methods

    private func setupFromNib() {
        Bundle(for: type(of: self)).loadNibNamed("ClipInformationView", owner: self, options: nil)
        self.baseView.frame = self.bounds
        self.addSubview(self.baseView)
        self.sendSubviewToBack(self.baseView)
    }

    private func setupAppearance() {
        self.siteUrlTitleLabel.text = L10n.clipInformationViewSiteUrlTitle
        self.imageUrlTitleLabel.text = L10n.clipInformationViewImageUrlTitle

        self.siteUrlButton.addInteraction(UIContextMenuInteraction(delegate: self))
        self.imageUrlButton.addInteraction(UIContextMenuInteraction(delegate: self))

        self.imageView = UIImageView(frame: .init(origin: .zero, size: .zero))
        self.imageView.contentMode = .scaleAspectFit
        self.baseView.addSubview(self.imageView)
    }

    private func updateImageViewFrame() {
        self.imageView.frame = self.calcInitialFrame()
    }

    public func calcInitialFrame() -> CGRect {
        guard let dataSource = self.dataSource, let image = dataSource.previewImage(self) else {
            return .zero
        }
        let bounds = dataSource.previewPageBounds(self)
        let scale = ClipPreviewPageView.calcScaleToFit(image, on: bounds.size)
        let resizedImageSize = image.size.scaled(by: scale)
        return CGRect(origin: .init(x: (frame.size.width - resizedImageSize.width) / 2,
                                    y: -resizedImageSize.height + self.safeAreaInsets.top + 80),
                      size: resizedImageSize)
    }
}

extension ClipInformationView: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard self.tags.indices.contains(indexPath.row) else { return }
        self.delegate?.clipInformationView(self, didSelectTag: self.tags[indexPath.row])
    }
}

extension ClipInformationView: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.tags.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionView.cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? TagCollectionViewCell else { return dequeuedCell }
        guard self.tags.indices.contains(indexPath.row) else { return dequeuedCell }

        cell.title = self.tags[indexPath.row]
        cell.displayMode = .normal

        return cell
    }
}

extension ClipInformationView: UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDelegateFlowLayout

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard self.tags.indices.contains(indexPath.row) else { return .zero }
        let preferredSize = TagCollectionViewCell.preferredSize(for: self.tags[indexPath.row])
        return CGSize(width: fmin(preferredSize.width, collectionView.frame.width), height: preferredSize.height)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 0, bottom: 16, right: 0)
    }
}

extension ClipInformationView: UIContextMenuInteractionDelegate {
    // MARK: - UIContextMenuInteractionDelegate

    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let button = interaction.view as? UIButton,
            let text = button.titleLabel?.text,
            let url = URL(string: text)
        else {
            return nil
        }
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: self.makePreviewProvider(for: url),
                                          actionProvider: self.makeActionProvider(for: url))
    }

    private func makePreviewProvider(for url: URL) -> (() -> UIViewController) {
        let viewController = UIViewController()

        let webView = WKWebView(frame: .zero)
        viewController.view = webView
        webView.load(URLRequest(url: url))

        return { viewController }
    }

    private func makeActionProvider(for url: URL) -> UIContextMenuActionProvider {
        let open = UIAction(title: L10n.clipInformationViewContextMenuOpen, image: UIImage(systemName: "square.and.arrow.up.fill")) { _ in
            self.delegate?.clipInformationView(self, shouldOpen: url)
        }
        let copy = UIAction(title: L10n.clipInformationViewContextMenuCopy, image: UIImage(systemName: "square.on.square.fill")) { _ in
            self.delegate?.clipInformationView(self, shouldCopy: url)
        }
        return { _ in UIMenu(title: "", children: [open, copy]) }
    }
}

private extension CGSize {
    func scaled(by scale: CGFloat) -> Self {
        return .init(width: self.width * scale, height: self.height * scale)
    }
}
