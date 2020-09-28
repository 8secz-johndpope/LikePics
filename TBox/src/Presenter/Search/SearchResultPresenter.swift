//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol SearchResultViewProtocol: AnyObject {
    func apply(_ clips: [Clip])
    func apply(selection: Set<Clip>)
    func presentPreview(forClipId clipId: Clip.Identity)
    func setEditing(_ editing: Bool)
    func showErrorMessage(_ message: String)
}

enum SearchContext {
    case keywords([String])
    case tag(Tag)

    var title: String {
        switch self {
        case let .keywords(value):
            return value.joined(separator: ", ")

        case let .tag(value):
            return value.name
        }
    }
}

protocol SearchResultPresenterProtocol {
    var clips: [Clip] { get }
    var context: SearchContext { get }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data?

    func setup(with view: SearchResultViewProtocol)
    func setEditing(_ editing: Bool)
    func select(clipId: Clip.Identity)
    func deselect(clipId: Clip.Identity)
    func selectAll()
    func deselectAll()
    func deleteSelectedClips()
    func hideSelectedClips()
    func unhideSelectedClips()
}

class SearchResultPresenter {
    private let clipStorage: ClipStorageProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let queryService: ClipQueryServiceProtocol
    private let logger: TBoxLoggable

    private var clipsQuery: ClipListQuery
    private var storage = Set<AnyCancellable>()

    let context: SearchContext

    private(set) var clips: [Clip] = [] {
        didSet {
            self.view?.apply(clips)
        }
    }

    private var selectedClips: [Clip] {
        return self.selections
            .compactMap { selection in
                return self.clips.first(where: { selection == $0.identity })
            }
    }

    private var selections: Set<Clip.Identity> = .init() {
        didSet {
            self.view?.apply(selection: Set(self.selectedClips))
        }
    }

    private var isEditing: Bool = false {
        didSet {
            self.selections = []
            self.view?.setEditing(self.isEditing)
        }
    }

    private weak var view: SearchResultViewProtocol?

    // MARK: - Lifecycle

    init?(context: SearchContext,
          clipStorage: ClipStorageProtocol,
          settingStorage: UserSettingsStorageProtocol,
          queryService: ClipQueryServiceProtocol,
          logger: TBoxLoggable)
    {
        self.context = context
        self.clipStorage = clipStorage
        self.settingStorage = settingStorage
        self.queryService = queryService
        self.logger = logger

        switch context {
        case let .keywords(values):
            switch queryService.queryClips(matchingKeywords: values) {
            case let .success(query):
                self.clipsQuery = query

            case let .failure(error):
                logger.write(ConsoleLog(level: .error, message: "Failed to search clips. (code: \(error.rawValue))"))
                return nil
            }

        case let .tag(value):
            switch queryService.queryClips(tagged: value) {
            case let .success(query):
                self.clipsQuery = query

            case let .failure(error):
                logger.write(ConsoleLog(level: .error, message: "Failed to search clips. (code: \(error.rawValue))"))
                return nil
            }
        }
    }
}

extension SearchResultPresenter: SearchResultPresenterProtocol {
    // MARK: - SearchResultPresenterProtocol

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data? {
        let nullableClipItem: ClipItem? = {
            switch layer {
            case .primary:
                return clip.primaryItem

            case .secondary:
                return clip.secondaryItem

            case .tertiary:
                return clip.tertiaryItem
            }
        }()
        guard let clipItem = nullableClipItem else { return nil }

        switch self.clipStorage.readThumbnailData(of: clipItem) {
        case let .success(data):
            return data

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read albums. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtGetImageData)\n(\(error.makeErrorCode())")
            return nil
        }
    }

    func setup(with view: SearchResultViewProtocol) {
        self.view = view
        self.clipsQuery.clips
            .catch { _ -> AnyPublisher<[Clip], Never> in
                return Just([Clip]()).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
            .combineLatest(self.settingStorage.showHiddenItems)
            .sink(receiveCompletion: { [weak self] _ in
                self?.logger.write(ConsoleLog(level: .error, message: "Unexpectedly finished observing at TopClipsView."))
            }, receiveValue: { [weak self] clips, showHiddenItems in
                guard let self = self else { return }

                self.clips = clips
                    .filter({ clip in
                        guard showHiddenItems else { return !clip.isHidden }
                        return true
                    })
                    .sorted(by: { $0.registeredDate > $1.registeredDate })

                let newClips = Set(self.clips.map { $0.identity })
                if !self.selections.isSubset(of: newClips) {
                    self.selections = self.selections.subtracting(self.selections.subtracting(newClips))
                }
            })
            .store(in: &self.storage)
    }

    func setEditing(_ editing: Bool) {
        self.isEditing = editing
    }

    func select(clipId: Clip.Identity) {
        if self.isEditing {
            self.selections.insert(clipId)
        } else {
            self.selections = Set([clipId])
            self.view?.presentPreview(forClipId: clipId)
        }
    }

    func selectAll() {
        guard self.isEditing else { return }
        self.selections = Set(self.clips.map { $0.identity })
    }

    func deselect(clipId: Clip.Identity) {
        guard self.selections.contains(clipId) else { return }
        self.selections.remove(clipId)
    }

    func deselectAll() {
        self.selections = []
    }

    func deleteSelectedClips() {
        if case let .failure(error) = self.clipStorage.delete(self.selectedClips) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read image. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.isEditing = false
    }

    func hideSelectedClips() {
        if case let .failure(error) = self.clipStorage.update(self.selectedClips, byHiding: true) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read image. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.isEditing = false
    }

    func unhideSelectedClips() {
        if case let .failure(error) = self.clipStorage.update(self.selectedClips, byHiding: false) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read image. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.isEditing = false
    }
}

extension SearchResultPresenter: ClipsListNavigationPresenterDataSource {
    // MARK: - ClipsListNavigationPresenterDataSource

    func clipsCount(_ presenter: ClipsListNavigationItemsPresenter) -> Int {
        return self.clips.count
    }

    func selectedClipsCount(_ presenter: ClipsListNavigationItemsPresenter) -> Int {
        return self.selections.count
    }
}

extension SearchResultPresenter: ClipsListToolBarItemsPresenterDataSouce {
    // MARK: - ClipsListToolBarItemsPresenterDataSouce

    func selectedClipsCount(_ presenter: ClipsListToolBarItemsPresenter) -> Int {
        return self.selections.count
    }
}
