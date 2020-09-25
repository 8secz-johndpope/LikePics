//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol ClipQuery {
    var clip: CurrentValueSubject<Clip, Error> { get }
}
