//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit
import UIKit

public class TagSelectionViewController: UIViewController {
    typealias Dependency = TagSelectionViewModelType

    enum Section {
        case main
    }

    private let viewModel: TagSelectionViewModelType
    private let emptyMessageView = EmptyMessageView()
    private lazy var alertContainer = TextEditAlert(
        configuration: .init(title: L10n.tagListViewAlertForAddTitle,
                             message: L10n.tagListViewAlertForAddMessage,
                             placeholder: L10n.tagListViewAlertForAddPlaceholder)
    )

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var dataSource: UICollectionViewDiffableDataSource<Section, Tag>!
    private var cancellableBag: Set<AnyCancellable> = .init()

    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var collectionView: TagCollectionView!

    // MARK: - Lifecycle

    public init(viewModel: TagSelectionViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: "TagSelectionViewController", bundle: Bundle(for: Self.self))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        // HACK: nibから読み込んでいるため初期サイズがnibに引きずられる
        //       これによりCollectionViewのレイアウトが初回表示時にズレるのを防ぐ
        self.view.frame = self.navigationController?.view.frame ?? self.view.frame

        self.setupNavigationBar()
        self.setupCollectionView()
        self.setupSearchBar()
        self.setupEmptyMessage()

        self.bind(to: viewModel)
    }

    // MARK: - Methods

    private func startAddingTag() {
        self.alertContainer.present(withText: nil, on: self) {
            $0?.isEmpty != true
        } completion: { [weak self] action in
            guard case let .saved(text: tag) = action else { return }
            self?.viewModel.inputs.createdTag.send(tag)
        }
    }

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.tags
            .map { $0.isEmpty }
            .receive(on: DispatchQueue.main)
            .assignNoRetain(to: \.isHidden, on: self.searchBar)
            .store(in: &self.cancellableBag)
        dependency.outputs.tags
            .map { $0.isEmpty }
            .receive(on: DispatchQueue.main)
            .assignNoRetain(to: \.isHidden, on: self.collectionView)
            .store(in: &self.cancellableBag)
        dependency.outputs.tags
            .map { $0.isEmpty ? 1 : 0 }
            .receive(on: DispatchQueue.main)
            .assignNoRetain(to: \.alpha, on: self.emptyMessageView)
            .store(in: &self.cancellableBag)
        dependency.outputs.tags
            .filter { $0.isEmpty }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.searchBar.resignFirstResponder()
                self?.searchBar.text = nil
                self?.viewModel.inputs.inputtedQuery.send("")
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.filteredTags
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tags in
                var snapshot = NSDiffableDataSourceSnapshot<Section, Tag>()
                snapshot.appendSections([.main])
                snapshot.appendItems(tags)
                self?.dataSource.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &self.cancellableBag)
    }

    // MARK: Navigation Bar

    private func setupNavigationBar() {
        // TODO: タイトルの追加

        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAdd))
        let saveItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.didTapSave))

        self.navigationItem.rightBarButtonItems = [addItem, saveItem]
    }

    @objc
    func didTapAdd() {
        self.startAddingTag()
    }

    @objc
    func didTapSave() {
        // TODO:
    }

    // MARK: Collection View

    private func setupCollectionView() {
        self.collectionView.collectionViewLayout = self.createLayout()
        self.collectionView.delegate = self
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = true
        self.dataSource = .init(collectionView: self.collectionView,
                                cellProvider: TagCollectionView.cellProvider(dataSource: self))
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ -> NSCollectionLayoutSection? in
            let groupEdgeSpacing = NSCollectionLayoutEdgeSpacing(leading: nil, top: nil, trailing: nil, bottom: .fixed(4))
            let section = TagCollectionView.createLayoutSection(groupEdgeSpacing: groupEdgeSpacing)
            section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 4, trailing: 12)
            return section
        }
        return layout
    }

    // MARK: SearchBar

    private func setupSearchBar() {
        self.searchBar.delegate = self
        self.searchBar.showsCancelButton = false
    }

    // MARK: EmptyMessage

    private func setupEmptyMessage() {
        self.view.addSubview(self.emptyMessageView)
        self.emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        self.emptyMessageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        self.emptyMessageView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        self.emptyMessageView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        self.emptyMessageView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true

        self.emptyMessageView.title = L10n.tagListViewEmptyTitle
        self.emptyMessageView.message = L10n.tagListViewEmptyMessage
        self.emptyMessageView.actionButtonTitle = L10n.tagListViewEmptyActionTitle
        self.emptyMessageView.delegate = self

        self.emptyMessageView.alpha = 0
    }
}

extension TagSelectionViewController: TagCollectionViewDataSource {
    // MARK: - TagCollectionViewDataSource

    public func displayMode(_ collectionView: UICollectionView) -> TagCollectionViewCell.DisplayMode {
        return .checkAtSelect
    }

    public func visibleDeleteButton(_ collectionView: UICollectionView) -> Bool {
        return false
    }

    public func delegate(_ collectionView: UICollectionView) -> TagCollectionViewCellDelegate? {
        return nil
    }
}

extension TagSelectionViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let tagId = self.dataSource.itemIdentifier(for: indexPath)?.identity else { return }
        self.viewModel.inputs.select.send(tagId)
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let tagId = self.dataSource.itemIdentifier(for: indexPath)?.identity else { return }
        self.viewModel.inputs.deselect.send(tagId)
    }
}

extension TagSelectionViewController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        RunLoop.main.perform { [weak self] in
            guard let text = self?.searchBar.text else { return }
            self?.viewModel.inputs.inputtedQuery.send(text)
        }
    }

    public func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let text = self?.searchBar.text else { return }
            self?.viewModel.inputs.inputtedQuery.send(text)
        }
        return true
    }

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.setShowsCancelButton(true, animated: true)
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBar.setShowsCancelButton(false, animated: true)
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }
}

extension TagSelectionViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    public func didTapActionButton(_ view: EmptyMessageView) {
        self.startAddingTag()
    }
}
