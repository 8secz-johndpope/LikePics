//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol TagCollectionViewCellDelegate: AnyObject {
    func didTapDeleteButton(_ cell: TagCollectionViewCell)
}

public class TagCollectionViewCell: UICollectionViewCell {
    public enum DisplayMode {
        case normal
        case checkAtSelect
    }

    public static var nib: UINib {
        return UINib(nibName: "TagCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public var title: String? {
        didSet {
            self.updateLabel()
        }
    }

    public var count: Int? {
        didSet {
            self.updateLabel()
        }
    }

    public var displayMode: DisplayMode = .checkAtSelect {
        didSet {
            self.updateForDisplayMode()
        }
    }

    public var visibleDeleteButton: Bool {
        get {
            return !self.deleteButtonContainer.isHidden
        }
        set {
            self.deleteButtonContainer.isHidden = !newValue
            self.labelMaxWidthConstraint.constant = newValue
                ? 240 - self.deleteButtonWidthConstraint.constant
                : 240
        }
    }

    public var visibleCountIfPossible: Bool = true {
        didSet {
            self.updateLabel()
        }
    }

    override public var isSelected: Bool {
        didSet {
            self.updateForDisplayMode()
        }
    }

    public var isHiddenTag: Bool = false {
        didSet {
            self.hashTagLabel.textColor = isHiddenTag ? .secondaryLabel : .label
            self.titleLabel.textColor = isHiddenTag ? .secondaryLabel : .label
        }
    }

    @IBOutlet var hashTagLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var deleteButtonContainer: UIView!
    @IBOutlet var labelMaxWidthConstraint: NSLayoutConstraint!
    @IBOutlet var deleteButtonWidthConstraint: NSLayoutConstraint!

    public weak var delegate: TagCollectionViewCellDelegate?

    // MARK: - Methods

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        self.updateRadius()
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.layer.borderColor = UIColor.systemGray3.cgColor
        }
    }

    @IBAction func tapDeleteButton(_ sender: UIButton) {
        self.delegate?.didTapDeleteButton(self)
    }

    func setupAppearance() {
        self.layer.cornerCurve = .continuous

        self.visibleDeleteButton = false

        self.updateRadius()
        self.updateColors()
        self.updateForDisplayMode()
    }

    func updateRadius() {
        self.layer.cornerRadius = self.bounds.size.height / 4
    }

    func updateColors() {
        self.layer.borderColor = UIColor.systemGray3.cgColor
    }

    func updateForDisplayMode() {
        switch (self.displayMode, self.isSelected) {
        case (.checkAtSelect, true):
            self.contentView.backgroundColor = UIColor.systemGreen
            self.layer.borderWidth = 0

        default:
            self.contentView.backgroundColor = UIColor.systemBackground
            self.layer.borderWidth = 1
        }

        self.updateLabel()
    }

    func updateLabel() {
        guard let title = self.title else {
            self.titleLabel.text = nil
            return
        }
        if let count = self.count, self.visibleCountIfPossible {
            self.titleLabel.text = "\(title) (\(count))"
        } else {
            self.titleLabel.text = title
        }
    }
}
