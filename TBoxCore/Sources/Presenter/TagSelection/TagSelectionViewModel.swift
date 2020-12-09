//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

public protocol TagSelectionViewModelType {
    var inputs: TagSelectionViewModelInputs { get }
    var outputs: TagSelectionViewModelOutputs { get }
}

public protocol TagSelectionViewModelInputs {
    var select: PassthroughSubject<Tag.Identity, Never> { get }
    var deselect: PassthroughSubject<Tag.Identity, Never> { get }
    var inputtedQuery: PassthroughSubject<String, Never> { get }
    var createdTag: PassthroughSubject<String, Never> { get }
}

public protocol TagSelectionViewModelOutputs {
    var tags: CurrentValueSubject<[Tag], Never> { get }
    var filteredTags: CurrentValueSubject<[Tag], Never> { get }
    var errorMessage: PassthroughSubject<String, Never> { get }
}

public class TagSelectionViewModel: TagSelectionViewModelType,
    TagSelectionViewModelInputs,
    TagSelectionViewModelOutputs
{
    // MARK: - Properties

    // MARK: TagSelectionViewModelType

    public var inputs: TagSelectionViewModelInputs { self }
    public var outputs: TagSelectionViewModelOutputs { self }

    // MARK: TagSelectionViewModelInputs

    public let select: PassthroughSubject<Tag.Identity, Never> = .init()
    public let deselect: PassthroughSubject<Tag.Identity, Never> = .init()
    public let inputtedQuery: PassthroughSubject<String, Never> = .init()
    public let createdTag: PassthroughSubject<String, Never> = .init()

    // MARK: TagSelectionViewModelOutputs

    public let tags: CurrentValueSubject<[Tag], Never> = .init([])
    public let filteredTags: CurrentValueSubject<[Tag], Never> = .init([])
    public let errorMessage: PassthroughSubject<String, Never> = .init()

    // MARK: Privates

    private let query: TagListQuery
    private let commandService: TagCommandServiceProtocol
    private let logger: TBoxLoggable
    private var searchStorage: SearchableTagsStorage = .init()
    private var cancellableBag: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    public init(query: TagListQuery,
                commandService: TagCommandServiceProtocol,
                logger: TBoxLoggable)
    {
        self.query = query
        self.commandService = commandService
        self.logger = logger

        self.bind()
    }

    private func bind() {
        self.query.tags
            .catch { _ in Just([]) }
            .eraseToAnyPublisher()
            .combineLatest(self.inputtedQuery)
            .sink { [weak self] tags, query in
                guard let self = self else { return }

                self.searchStorage.updateCache(tags)
                let filteredTags = self.searchStorage.resolveTags(byQuery: query)
                    .sorted(by: { $0.name < $1.name })

                self.filteredTags.send(filteredTags)
                self.tags.send(tags)
            }
            .store(in: &self.cancellableBag)

        self.createdTag
            .sink { [weak self] name in
                guard let self = self else { return }
                guard case let .failure(error) = self.commandService.create(tagWithName: name) else { return }
                switch error {
                case .duplicated:
                    self.logger.write(ConsoleLog(level: .info, message: """
                    Duplicated tag name "\(name)".
                    """))
                    self.errorMessage.send(L10n.errorTagAddDuplicated)

                default:
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to add tag.
                    """))
                    self.errorMessage.send(L10n.errorTagAddDefault)
                }
            }
            .store(in: &self.cancellableBag)
    }
}
