//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct ReferenceTag: Equatable {
    public let id: UUID
    public let name: String
    public let isDirty: Bool

    // MARK: - Lifecycle

    public init(id: UUID, name: String, isDirty: Bool = false) {
        self.id = id
        self.name = name
        self.isDirty = isDirty
    }
}

extension ReferenceTag: Identifiable {
    public typealias Identity = Tag.Identity

    public var identity: Tag.Identity {
        return self.id
    }
}

extension ReferenceTag: Hashable {}
