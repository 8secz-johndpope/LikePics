//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

enum ThumbnailLayer {
    case primary
    case secondary
    case tertiary
}

protocol TopClipsListViewProtocol: AnyObject {
    func apply(_ clips: [Clip])
    func apply(selection: Set<Clip>)
    func presentPreview(forClipId clipId: Clip.Identity, availability: @escaping (_ isAvailable: Bool) -> Void)
    func setEditing(_ editing: Bool)
    func showErrorMessage(_ message: String)
}

protocol TopClipsListPresenterProtocol {
    var clips: [Clip] { get }
    var previewingClip: Clip? { get }

    func viewDidAppear()

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data?

    func setup(with view: TopClipsListViewProtocol)
    func setEditing(_ editing: Bool)
    func select(clipId: Clip.Identity)
    func deselect(clipId: Clip.Identity)
    func selectAll()
    func deselectAll()
    func deleteSelectedClips()
    func hideSelectedClips()
    func unhideSelectedClips()
    func addTagsToSelectedClips(_ tags: [Tag])
}

class TopClipsListPresenter {
    private let query: ClipListQuery
    private let clipStorage: ClipStorageProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var storage = Set<AnyCancellable>()

    private(set) var clips: [Clip] = [] {
        didSet {
            self.view?.apply(clips)
        }
    }

    private var previewingClipId: Clip.Identity?

    var previewingClip: Clip? {
        guard let id = self.previewingClipId else { return nil }
        return self.clips.first(where: { $0.identity == id })
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

    private weak var view: TopClipsListViewProtocol?

    // MARK: - Lifecycle

    init(query: ClipListQuery,
         clipStorage: ClipStorageProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.clipStorage = clipStorage
        self.settingStorage = settingStorage
        self.logger = logger
    }
}

extension TopClipsListPresenter: TopClipsListPresenterProtocol {
    // MARK: - TopClipsListPresenterProtocol

    func viewDidAppear() {
        self.previewingClipId = nil
    }

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

    func setup(with view: TopClipsListViewProtocol) {
        self.view = view
        self.query.clips
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

                self.isEditing = false
                self.selections = []
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
            self.view?.presentPreview(forClipId: clipId) { [weak self] isAvailable in
                guard isAvailable else { return }
                self?.previewingClipId = clipId
            }
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

    func addTagsToSelectedClips(_ tags: [Tag]) {
        if case let .failure(error) = self.clipStorage.update(self.selectedClips, byAddingTags: tags) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add tags. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.isEditing = false
    }
}

extension TopClipsListPresenter: ClipsListNavigationPresenterDataSource {
    // MARK: - ClipsListNavigationPresenterDataSource

    func clipsCount(_ presenter: ClipsListNavigationItemsPresenter) -> Int {
        return self.clips.count
    }

    func selectedClipsCount(_ presenter: ClipsListNavigationItemsPresenter) -> Int {
        return self.selections.count
    }
}

extension TopClipsListPresenter: ClipsListToolBarItemsPresenterDataSouce {
    // MARK: - ClipsListToolBarItemsPresenterDataSouce

    func selectedClipsCount(_ presenter: ClipsListToolBarItemsPresenter) -> Int {
        return self.selections.count
    }
}
