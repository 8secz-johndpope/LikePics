//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct LightweightClip: Equatable {
    public let id: String
    public let url: URL?
    public let description: String?
    public let tags: [LightweightTag]
    public let isHidden: Bool
    public let registeredDate: Date

    // MARK: - Lifecycle

    public init(id: String,
                url: URL?,
                description: String?,
                tags: [LightweightTag],
                isHidden: Bool,
                registeredDate: Date)
    {
        self.id = id
        self.url = url
        self.description = description
        self.tags = tags
        self.isHidden = isHidden
        self.registeredDate = registeredDate
    }
}

extension LightweightClip: Identifiable {
    public typealias Identity = Clip.Identity

    public var identity: Clip.Identity {
        return self.id
    }
}

extension LightweightClip: Hashable {}
