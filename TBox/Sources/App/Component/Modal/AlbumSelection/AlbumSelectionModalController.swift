//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Smoothie
import TBoxUIKit
import UIKit

class AlbumSelectionModalController: UIViewController {
    typealias Layout = AlbumSelectionModalLayout
    typealias Store = LikePics.Store<AlbumSelectionModalState, AlbumSelectionModalAction, AlbumSelectionModalDependency>

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var searchBar: UISearchBar!
    private let emptyMessageView = EmptyMessageView()
    private var dataSource: Layout.DataSource!

    private let thumbnailLoader: ThumbnailLoaderProtocol

    // MARK: Component

    private let albumAdditionAlert: TextEditAlertController

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(state: AlbumSelectionModalState,
         albumAdditionAlertState: TextEditAlertState,
         dependency: AlbumSelectionModalDependency,
         thumbnailLoader: ThumbnailLoaderProtocol)
    {
        self.store = .init(initialState: state, dependency: dependency, reducer: AlbumSelectionModalReducer.self)
        self.albumAdditionAlert = .init(state: albumAdditionAlertState)
        self.thumbnailLoader = thumbnailLoader
        super.init(nibName: nil, bundle: nil)

        albumAdditionAlert.textEditAlertDelegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Life-Cycle Methods

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        store.execute(.viewDidDisappear)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureDataSource()
        configureSearchBar()
        configureNavigationBar()
        configureEmptyMessageView()

        bind(to: store)

        store.execute(.viewDidLoad)
    }
}

// MARK: - Bind

extension AlbumSelectionModalController {
    private func bind(to store: Store) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }

            DispatchQueue.global().async {
                var snapshot = Layout.Snapshot()
                snapshot.appendSections([.main])
                snapshot.appendItems(state.albums.displayableValues)
                self.dataSource.apply(snapshot, animatingDifferences: true)
            }

            self.searchBar.isHidden = !state.isCollectionViewDisplaying
            self.collectionView.isHidden = !state.isCollectionViewDisplaying

            self.emptyMessageView.alpha = state.isEmptyMessageViewDisplaying ? 1 : 0

            self.presentAlertIfNeeded(for: state.alert)

            if state.isDismissed {
                self.dismiss(animated: true, completion: nil)
            }
        }
        .store(in: &subscriptions)
    }

    private func presentAlertIfNeeded(for alert: AlbumSelectionModalState.Alert?) {
        switch alert {
        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case .addition:
            albumAdditionAlert.present(with: "", validator: { $0?.isEmpty == false }, on: self)

        case .none:
            break
        }
    }

    private func presentErrorMessageAlertIfNeeded(message: String?) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        })
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Configuration

extension AlbumSelectionModalController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color

        searchBar = UISearchBar()
        searchBar.backgroundColor = .clear
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyMessageView)
        NSLayoutConstraint.activate(emptyMessageView.constraints(fittingIn: view.safeAreaLayoutGuide))
    }

    private func configureDataSource() {
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        dataSource = Layout.createDataSource(collectionView: collectionView,
                                             thumbnailLoader: thumbnailLoader)
    }

    private func configureSearchBar() {
        searchBar.barStyle = .default
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.showsCancelButton = false
        searchBar.placeholder = L10n.placeholderSearchAlbum
        searchBar.backgroundColor = Asset.Color.backgroundClient.color
    }

    private func configureNavigationBar() {
        navigationItem.title = L10n.albumSelectionViewTitle

        let addItem = UIBarButtonItem(systemItem: .add, primaryAction: .init(handler: { [weak self] _ in
            self?.store.execute(.addButtonTapped)
        }), menu: nil)

        navigationItem.leftBarButtonItem = addItem
    }

    private func configureEmptyMessageView() {
        emptyMessageView.alpha = 0
        emptyMessageView.title = L10n.albumListViewEmptyTitle
        emptyMessageView.message = L10n.albumListViewEmptyMessage
        emptyMessageView.actionButtonTitle = L10n.albumListViewEmptyActionTitle
        emptyMessageView.delegate = self
    }
}

extension AlbumSelectionModalController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let album = self.dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.selected(album.identity))
    }
}

extension AlbumSelectionModalController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        RunLoop.main.perform {
            self.store.execute(.searchQueryChanged(searchBar.text ?? ""))
        }
    }

    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // HACK: marked text 入力を待つために遅延を設ける
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            RunLoop.main.perform {
                self.store.execute(.searchQueryChanged(searchBar.text ?? ""))
            }
        }
        return true
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension AlbumSelectionModalController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    func didTapActionButton(_ view: EmptyMessageView) {
        store.execute(.emptyMessageViewActionButtonTapped)
    }
}

extension AlbumSelectionModalController: TextEditAlertDelegate {
    // MARK: - TextEditAlertDelegate

    func textEditAlert(_ id: UUID, didTapSaveWithText text: String) {
        store.execute(.alertSaveButtonTapped(text: text))
    }

    func textEditAlertDidCancel(_ id: UUID) {
        store.execute(.alertDismissed)
    }
}
