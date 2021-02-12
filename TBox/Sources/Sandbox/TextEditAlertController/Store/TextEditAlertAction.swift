//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

enum TextEditAlertAction {
    case textChanged(text: String)
    case saveActionTapped
    case cancelActionTapped
    case dismissed

    case completed(withText: String)
}

extension TextEditAlertAction: Action {}
