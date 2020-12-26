//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

protocol ClipCollectionToolBarViewModelType {
    var inputs: ClipCollectionToolBarViewModelInputs { get }
    var outputs: ClipCollectionToolBarViewModelOutputs { get }
}

protocol ClipCollectionToolBarViewModelInputs {
    var selectedClipsCount: CurrentValueSubject<Int, Never> { get }
    var operation: CurrentValueSubject<ClipCollection.Operation, Never> { get }
}

protocol ClipCollectionToolBarViewModelOutputs {
    var isHidden: CurrentValueSubject<Bool, Never> { get }
    var items: CurrentValueSubject<[ClipCollection.ToolBarItem], Never> { get }
    var selectionCount: CurrentValueSubject<Int, Never> { get }
}

class ClipCollectionToolBarViewModel: ClipCollectionToolBarViewModelType,
    ClipCollectionToolBarViewModelInputs,
    ClipCollectionToolBarViewModelOutputs
{
    // MARK: - Properties

    // MARK: ClipCollectionToolBarViewModelType

    var inputs: ClipCollectionToolBarViewModelInputs { self }
    var outputs: ClipCollectionToolBarViewModelOutputs { self }

    // MARK: ClipCollectionToolBarViewModelInputs

    var selectedClipsCount: CurrentValueSubject<Int, Never> = .init(0)
    var operation: CurrentValueSubject<ClipCollection.Operation, Never> = .init(.none)

    // MARK: ClipCollectionToolBarViewModelOutputs

    var isHidden: CurrentValueSubject<Bool, Never> = .init(false)
    var items: CurrentValueSubject<[ClipCollection.ToolBarItem], Never> = .init([])
    var selectionCount: CurrentValueSubject<Int, Never> = .init(0)

    // MARK: Privates

    private let context: ClipCollection.Context
    private var cancellableBag: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    init(context: ClipCollection.Context) {
        self.context = context

        // MARK: Bind

        self.selectedClipsCount
            .sink { [weak self] count in self?.selectionCount.send(count) }
            .store(in: &self.cancellableBag)

        self.operation
            .map { $0 == .selecting }
            .sink { [weak self] isEditing in self?.isHidden.send(!isEditing) }
            .store(in: &self.cancellableBag)

        self.selectedClipsCount
            .sink { [weak self] count in
                guard let self = self else { return }
                // swiftlint:disable:next empty_count
                let isEnabled = count > 0

                self.items.send([
                    .init(kind: .add, isEnabled: isEnabled),
                    .init(kind: .changeVisibility, isEnabled: isEnabled),
                    .init(kind: .share, isEnabled: isEnabled),
                    self.context.isAlbum
                        ? .init(kind: .removeFromAlbum, isEnabled: isEnabled)
                        : .init(kind: .delete, isEnabled: isEnabled),
                    .init(kind: .merge, isEnabled: isEnabled && count > 1)
                ])
            }
            .store(in: &self.cancellableBag)
    }
}
