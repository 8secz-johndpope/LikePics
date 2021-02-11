//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

enum TextEditAlertReducer {
    typealias Dependency = HasTextValidator & HasTextEditAlertDelegate
    typealias State = TextEditAlertState
    typealias Action = TextEditAlertAction

    // MARK: - Methods

    static func execute(action: Action, state: State, dependency: Dependency) -> State {
        switch action {
        case let .textChanged(text: text):
            return state.updating(text: text, shouldReturn: dependency.textValidator(text))

        case .saveActionTapped:
            dependency.textEditAlertCompleted(state.text)
            return state

        case .cancelActionTapped:
            dependency.textEditAlertCancelled()
            return state
        }
    }
}
