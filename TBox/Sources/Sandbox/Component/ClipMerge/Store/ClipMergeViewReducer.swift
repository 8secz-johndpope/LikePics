//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias ClipMergeViewDependency = HasRouter
    & HasClipCommandService

enum ClipMergeViewReducer: Reducer {
    typealias Dependency = ClipMergeViewDependency
    typealias State = ClipMergeViewState
    typealias Action = ClipMergeViewAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        switch action {
        // MARK: - NavigationBar

        case .saveButtonTapped:
            let itemIds = state.items.map({ $0.id })
            let tagIds = state.tags.map({ $0.id })
            switch dependency.clipCommandService.mergeClipItems(itemIds: itemIds, tagIds: tagIds, inClipsHaving: Array(state.sourceClipIds)) {
            case .success:
                return (state.updating(isPresenting: false), .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipMergeViewErrorAtMerge)), .none)
            }

        // MARK: - Button Action

        case .tagAdditionButtonTapped:
            let effect = showTagSelectionModal(selections: Set(state.tags.map({ $0.id })), dependency: dependency)
            return (state, [effect])

        case let .tagDeleteButtonTapped(tagId):
            return (state.updating(tags: state.tags.filter({ $0.id != tagId })), .none)

        // MARK: - CollectionView

        case let .itemReordered(items):
            return (state.updating(items: items), .none)

        // MARK: - Modal Completion

        case let .tagsSelected(tags):
            guard let tags = tags else { return (state, .none) }
            let sortedTags = Array(tags).sorted(by: { $0.name < $1.name })
            return (state.updating(tags: sortedTags), .none)

        case .modalCompleted:
            return (state, .none) // NOP

        // MARK: - Alert Completion

        case .alertDismissed:
            return (state.updating(alert: nil), .none)
        }
    }
}

// MARK: - Router

extension ClipMergeViewReducer {
    static func showTagSelectionModal(selections: Set<Tag.Identity>, dependency: HasRouter) -> Effect<Action> {
        let stream = Deferred {
            Future<Action?, Never> { promise in
                let isPresented = dependency.router.showTagSelectionModal(selections: selections) { tags in
                    promise(.success(.tagsSelected(tags)))
                }
                if !isPresented {
                    promise(.success(.modalCompleted(false)))
                }
            }
        }
        return Effect(stream)
    }
}
