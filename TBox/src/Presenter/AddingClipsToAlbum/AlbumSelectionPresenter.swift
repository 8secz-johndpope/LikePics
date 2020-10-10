//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol AlbumSelectionPresenterDelegate: AnyObject {
    func albumSelectionPresenter(_ presenter: AlbumSelectionPresenter, didSelectAlbum: Album.Identity)
}

protocol AlbumSelectionViewProtocol: AnyObject {
    func apply(_ albums: [Album])
    func reload()
    func showErrorMessage(_ message: String)
    func close()
}

class AlbumSelectionPresenter {
    private let query: AlbumListQuery
    private let storage: ClipStorageProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var cancellableBag = Set<AnyCancellable>()

    private(set) var albums: [Album] = [] {
        didSet {
            self.view?.apply(self.albums)
        }
    }

    private var showHiddenItems: Bool = false {
        didSet {
            if oldValue != self.showHiddenItems {
                self.view?.reload()
            }
        }
    }

    weak var delegate: AlbumSelectionPresenterDelegate?
    weak var view: AlbumSelectionViewProtocol?

    // MARK: - Lifecycle

    init(query: AlbumListQuery,
         storage: ClipStorageProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.storage = storage
        self.settingStorage = settingStorage
        self.logger = logger
    }

    // MARK: - Methods

    func setup() {
        self.query
            .albums
            .catch { _ -> AnyPublisher<[Album], Never> in
                return Just([Album]()).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
            .combineLatest(self.settingStorage.showHiddenItems)
            .sink(receiveCompletion: { [weak self] _ in
                self?.logger.write(ConsoleLog(level: .error, message: "Unexpectedly finished observing at AlbumSelectionPresenter."))
            }, receiveValue: { [weak self] albums, showHiddenItems in
                guard let self = self else { return }
                self.albums = albums
                    .sorted(by: { $0.registeredDate > $1.registeredDate })
                self.showHiddenItems = showHiddenItems
            })
            .store(in: &self.cancellableBag)
    }

    func select(albumId: Album.Identity) {
        self.delegate?.albumSelectionPresenter(self, didSelectAlbum: albumId)
        self.view?.close()
    }

    func readThumbnailImageData(for album: Album) -> Data? {
        let thumbnailTarget: ClipItem? = {
            if self.showHiddenItems {
                return album.clips.first?.items.first
            } else {
                return album.clips.first(where: { !$0.isHidden })?.items.first
            }
        }()
        guard let clipItem = thumbnailTarget else { return nil }

        switch self.storage.readThumbnailData(of: clipItem) {
        case let .success(data):
            return data

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read image. (code: \(error.rawValue))"))
            // TODO: Localize
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
            return nil
        }
    }
}
