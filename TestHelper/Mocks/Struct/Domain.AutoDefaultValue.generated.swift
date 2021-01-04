// Generated using Sourcery 1.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

@testable import Domain

extension Album {
    static func makeDefault(
        id: UUID = UUID(),
        title: String = "",
        clips: [Clip] = [],
        isHidden: Bool = false,
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            id: id,
            title: title,
            clips: clips,
            isHidden: isHidden,
            registeredDate: registeredDate,
            updatedDate: updatedDate
        )
    }
}

extension Clip {
    static func makeDefault(
        id: UUID = UUID(),
        description: String? = nil,
        items: [ClipItem] = [],
        tags: [Tag] = [],
        isHidden: Bool = false,
        dataSize: Int = 0,
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            id: id,
            description: description,
            items: items,
            tags: tags,
            isHidden: isHidden,
            dataSize: dataSize,
            registeredDate: registeredDate,
            updatedDate: updatedDate
        )
    }
}

extension ClipItem {
    static func makeDefault(
        id: UUID = UUID(),
        url: URL? = nil,
        clipId: UUID = UUID(),
        clipIndex: Int = 0,
        imageId: UUID = UUID(),
        imageFileName: String = "",
        imageUrl: URL? = nil,
        imageSize: ImageSize = ImageSize.makeDefault(),
        imageDataSize: Int = 0,
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            id: id,
            url: url,
            clipId: clipId,
            clipIndex: clipIndex,
            imageId: imageId,
            imageFileName: imageFileName,
            imageUrl: imageUrl,
            imageSize: imageSize,
            imageDataSize: imageDataSize,
            registeredDate: registeredDate,
            updatedDate: updatedDate
        )
    }
}

extension ImageSize {
    static func makeDefault(
        height: Double = 0,
        width: Double = 0
    ) -> Self {
        return .init(
            height: height,
            width: width
        )
    }
}

extension ReferenceTag {
    static func makeDefault(
        id: UUID = UUID(),
        name: String = "",
        isDirty: Bool = false
    ) -> Self {
        return .init(
            id: id,
            name: name,
            isDirty: isDirty
        )
    }
}

extension Tag {
    static func makeDefault(
        id: UUID = UUID(),
        name: String = "",
        isHidden: Bool = false,
        clipCount: Int? = nil
    ) -> Self {
        return .init(
            id: id,
            name: name,
            isHidden: isHidden,
            clipCount: clipCount
        )
    }
}
