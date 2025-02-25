//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import RealmSwift

class RealmClipsResultQuery {
    private var token: NotificationToken?
    private let results: Results<ClipObject>
    private var subject: CurrentValueSubject<[Clip], Error>

    // MARK: - Lifecycle

    init(results: Results<ClipObject>) {
        self.results = results
        self.subject = .init(results.map({ Clip.make(by: $0) }))
        self.token = self.results.observe { [weak self] (change: RealmCollectionChange<Results<ClipObject>>) in
            switch change {
            case let .initial(results):
                self?.subject.send(results.map({ Clip.make(by: $0) }))

            case let .update(results, deletions: _, insertions: _, modifications: _):
                self?.subject.send(results.map({ Clip.make(by: $0) }))

            case let .error(error):
                self?.subject.send(completion: .failure(error))
            }
        }
    }

    deinit {
        self.token?.invalidate()
    }
}

extension RealmClipsResultQuery: ClipListQuery {
    // MARK: - ClipListQuery

    var clips: CurrentValueSubject<[Clip], Error> {
        return self.subject
    }
}
