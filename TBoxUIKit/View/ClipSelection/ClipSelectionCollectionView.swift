//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipSelectionCollectionView: UICollectionView {
    public static let cellIdentifier = "Cell"
    public static let headerIdentifier = "Header"

    // MARK: - Lifecycle

    override public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)

        self.registerCell()
        self.setupAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.registerCell()
        self.setupAppearance()
    }

    override public var contentSize: CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    override public var intrinsicContentSize: CGSize {
        return .init(width: UIView.noIntrinsicMetric, height: self.contentSize.height)
    }

    // MARK: - Methods

    private func registerCell() {
        self.register(ClipSelectionCollectionViewCell.nib,
                      forCellWithReuseIdentifier: Self.cellIdentifier)
        self.register(ClipSelectionCollectionViewHeader.nib,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                      withReuseIdentifier: Self.headerIdentifier)
    }

    private func setupAppearance() {
        self.collectionViewLayout = ClipCollectionLayout()
        self.allowsMultipleSelection = true
    }
}
