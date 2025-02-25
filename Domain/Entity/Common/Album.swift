//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct Album {
    public let id: UUID
    public let title: String
    /// - attention: 順序が保持されている
    public let clips: [Clip]
    public let isHidden: Bool
    public let registeredDate: Date
    public let updatedDate: Date

    private let _searchableTitle: String?

    // MARK: - Lifecycle

    public init(id: UUID,
                title: String,
                clips: [Clip],
                isHidden: Bool,
                registeredDate: Date,
                updatedDate: Date)
    {
        self.id = id
        self.title = title
        self.clips = clips
        self.isHidden = isHidden
        self.registeredDate = registeredDate
        self.updatedDate = updatedDate

        self._searchableTitle = title.transformToSearchableText()
    }

    init(id: UUID,
         title: String,
         clips: [Clip],
         isHidden: Bool,
         registeredDate: Date,
         updatedDate: Date,
         // swiftlint:disable:next identifier_name
         _searchableTitle: String?)
    {
        self.id = id
        self.title = title
        self.clips = clips
        self.isHidden = isHidden
        self.registeredDate = registeredDate
        self.updatedDate = updatedDate
        self._searchableTitle = _searchableTitle
    }

    // MARK: - Methods

    public func removingHiddenClips() -> Album {
        return .init(id: self.id,
                     title: self.title,
                     clips: self.clips.filter({ !$0.isHidden }),
                     isHidden: self.isHidden,
                     registeredDate: self.registeredDate,
                     updatedDate: self.updatedDate,
                     _searchableTitle: _searchableTitle)
    }

    public func updatingTitle(to title: String) -> Self {
        return .init(id: self.id,
                     title: title,
                     clips: self.clips,
                     isHidden: self.isHidden,
                     registeredDate: self.registeredDate,
                     updatedDate: self.updatedDate,
                     _searchableTitle: _searchableTitle)
    }

    public func updatingClips(to clips: [Clip]) -> Self {
        return .init(id: self.id,
                     title: self.title,
                     clips: clips,
                     isHidden: self.isHidden,
                     registeredDate: self.registeredDate,
                     updatedDate: self.updatedDate,
                     _searchableTitle: _searchableTitle)
    }
}

extension Album: Equatable {
    // MARK: - Equatable

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.clips == rhs.clips
    }
}

extension Album: Identifiable {
    public typealias Identity = UUID

    public var identity: UUID {
        return self.id
    }
}

extension Album: Hashable {
    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(clips)
    }
}

extension Album: Searchable {
    public var searchableText: String? { _searchableTitle }
}
