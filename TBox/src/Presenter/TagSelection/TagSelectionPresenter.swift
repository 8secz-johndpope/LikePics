//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol TagSelectionViewProtocol: AnyObject {
    func apply(_ tags: [Tag])
    func apply(selection: Set<Tag>)
    func showErrorMessage(_ message: String)
    func close()
}

protocol TagSelectionPresenterDelegate: AnyObject {
    func tagSelectionPresenter(_ presenter: TagSelectionPresenter, didSelectTagIds tagIds: Set<Tag.Identity>)
}

class TagSelectionPresenter {
    private let query: TagListQuery
    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    private let searchQuery: CurrentValueSubject<String, Error> = .init("")
    private var searchStorage: SearchableTagsStorage = .init()
    private var cancellableBag = Set<AnyCancellable>()

    private(set) var tags: [Tag] = [] {
        didSet {
            self.view?.apply(self.tags)
            self.view?.apply(selection: Set(self.selectedTags))
        }
    }

    private var selectedTags: [Tag] {
        return self.selections
            .compactMap { selection in
                return self.tags.first(where: { selection == $0.identity })
            }
    }

    private var selections: Set<Tag.Identity> {
        didSet {
            self.view?.apply(selection: Set(self.selectedTags))
        }
    }

    weak var delegate: TagSelectionPresenterDelegate?
    weak var view: TagSelectionViewProtocol?

    // MARK: - Lifecycle

    init(query: TagListQuery, selectedTags: [Tag.Identity], storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.query = query
        self.storage = storage
        self.logger = logger
        self.selections = Set(selectedTags)
    }

    // MARK: - Methods

    func setup() {
        self.query
            .tags
            .combineLatest(self.searchQuery)
            .sink(receiveCompletion: { [weak self] _ in
                self?.logger.write(ConsoleLog(level: .error, message: "Unexpectedly finished observing at TagSelectionView."))
            }, receiveValue: { [weak self] tags, searchQuery in
                guard let self = self else { return }

                self.searchStorage.updateCache(tags)
                let tags = self.searchStorage.resolveTags(byQuery: searchQuery)
                    .sorted(by: { $0.name < $1.name })

                self.tags = tags
            })
            .store(in: &self.cancellableBag)
    }

    func addTag(_ name: String) {
        if case let .failure(error) = self.storage.create(tagWithName: name) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add tag. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.tagListViewErrorAtAddTag)\n\(error.makeErrorCode())")
        }
    }

    func performSelection() {
        self.delegate?.tagSelectionPresenter(self, didSelectTagIds: self.selections)
        self.view?.close()
    }

    func select(tagId: Tag.Identity) {
        self.selections.insert(tagId)
    }

    func deselect(tagId: Tag.Identity) {
        guard self.selections.contains(tagId) else { return }
        self.selections.remove(tagId)
    }

    func performQuery(_ query: String) {
        self.searchQuery.send(query)
    }
}
