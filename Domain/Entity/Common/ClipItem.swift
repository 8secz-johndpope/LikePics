//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct ClipItem: Equatable {
    public let id: UUID
    public let url: URL?
    public let clipId: Clip.Identity
    public let clipIndex: Int
    public let imageFileName: String
    public let imageUrl: URL?
    public let imageSize: ImageSize
    public let registeredDate: Date
    public let updatedDate: Date

    // MARK: - Lifecycle

    public init(id: UUID,
                url: URL?,
                clipId: Clip.Identity,
                clipIndex: Int,
                imageFileName: String,
                imageUrl: URL?,
                imageSize: ImageSize,
                registeredDate: Date,
                updatedDate: Date)
    {
        self.id = id
        self.url = url
        self.clipId = clipId
        self.clipIndex = clipIndex
        self.imageFileName = imageFileName
        self.imageUrl = imageUrl
        self.imageSize = imageSize
        self.registeredDate = registeredDate
        self.updatedDate = updatedDate
    }
}

extension ClipItem: Identifiable {
    public typealias Identity = UUID

    public var identity: UUID {
        return self.id
    }
}

extension ClipItem: Hashable {}
