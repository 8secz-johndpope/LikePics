//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum CollectionChange<T> {
    case update(T)
    case error(Error)
}
