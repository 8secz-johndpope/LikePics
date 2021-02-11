//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum TagCollectionViewAction {
    case tagsUpdated([Tag])
    case searchQueryChanged(String)
    case settingUpdated(isHiddenItemEnabled: Bool)

    case errorAlertDismissed

    case createTag(name: String)
    case delete([Tag.Identity])
    case select(Tag)
    case hide(Tag.Identity)
    case reveal(Tag.Identity)
    case update(Tag.Identity, name: String)

    case emptyMessageViewActionButtonTapped
    case tagAdditionButtonTapped
    case uncategorizedTagButtonTapped
}
