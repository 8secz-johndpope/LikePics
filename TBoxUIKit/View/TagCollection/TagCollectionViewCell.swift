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
            self.updateAppearance()
        }
    }

    public var visibleDeleteButton: Bool {
        get {
            return !self.deleteButtonContainer.isHidden
        }
        set {
            self.deleteButtonContainer.isHidden = !newValue
            self.labelMaxWidthConstraint.constant = newValue
                ? 220 - self.deleteButtonWidthConstraint.constant
                : 220
        }
    }

    public var visibleCountIfPossible: Bool = true {
        didSet {
            self.updateLabel()
        }
    }

    override public var isSelected: Bool {
        didSet {
            self.updateAppearance()
        }
    }

    public var isHiddenTag: Bool = false {
        didSet {
            self.updateAppearance()
        }
    }

    @IBOutlet var hashTagLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var checkMarkIcon: UIImageView!
    @IBOutlet var hiddenIcon: UIImageView!

    @IBOutlet var checkMarkContainer: UIView!
    @IBOutlet var hiddenIconContainer: UIView!
    @IBOutlet var deleteButtonContainer: UIView!
    @IBOutlet var hashTagContainer: UIView!

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

        self.checkMarkIcon.tintColor = .white
        self.hiddenIcon.tintColor = UIColor.label.withAlphaComponent(0.8)

        self.updateRadius()
        self.updateColors()
        self.updateAppearance()
    }

    func updateRadius() {
        self.layer.cornerRadius = self.bounds.size.height / 4
    }

    func updateColors() {
        self.layer.borderColor = UIColor.systemGray3.cgColor
    }

    func updateAppearance() {
        switch (self.displayMode, self.isSelected) {
        case (.checkAtSelect, true):
            self.contentView.backgroundColor = UIColor.systemGreen
            self.layer.borderWidth = 0

            self.hiddenIconContainer.isHidden = true
            self.checkMarkContainer.isHidden = false
            self.hashTagContainer.isHidden = true

            self.titleLabel.textColor = isHiddenTag
                ? UIColor.white.withAlphaComponent(0.8)
                : .white

        default:
            self.contentView.backgroundColor = Asset.Color.secondaryBackground.color
            self.layer.borderWidth = 1

            self.hiddenIconContainer.isHidden = isHiddenTag ? false : true
            self.checkMarkContainer.isHidden = true
            self.hashTagContainer.isHidden = isHiddenTag ? true : false

            self.hashTagLabel.textColor = isHiddenTag
                ? UIColor.label.withAlphaComponent(0.8)
                : .label
            self.titleLabel.textColor = isHiddenTag
                ? UIColor.label.withAlphaComponent(0.8)
                : .label
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
