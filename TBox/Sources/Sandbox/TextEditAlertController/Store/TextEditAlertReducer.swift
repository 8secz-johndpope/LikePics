//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

typealias TextEditAlertDependency = HasTextValidator

enum TextEditAlertReducer: Reducer {
    typealias Dependency = TextEditAlertDependency
    typealias State = TextEditAlertState
    typealias Action = TextEditAlertAction

    // MARK: - Methods

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        switch action {
        case let .textChanged(text: text):
            return (state.updating(text: text, shouldReturn: dependency.textValidator(text)), .none)

        case .saveActionTapped, .cancelActionTapped, .dismissed:
            return (state, .none)
        }
    }
}
