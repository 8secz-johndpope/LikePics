//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ClipItemObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var url: String? = ""
    @objc dynamic var clipId: String = ""
    @objc dynamic var clipIndex: Int = 0
    @objc dynamic var imageFileName: String = ""
    @objc dynamic var imageUrl: String? = ""
    @objc dynamic var imageHeight: Double = 0
    @objc dynamic var imageWidth: Double = 0
    @objc dynamic var registeredAt = Date()
    @objc dynamic var updatedAt = Date()

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension Domain.ClipItem: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: ClipItemObject) -> Domain.ClipItem {
        let imageUrl: URL?
        if let imageUrlString = managedObject.imageUrl {
            imageUrl = URL(string: imageUrlString)
        } else {
            imageUrl = nil
        }

        let url: URL?
        if let urlString = managedObject.url {
            url = URL(string: urlString)
        } else {
            url = nil
        }

        return Domain.ClipItem(id: managedObject.id,
                               url: url,
                               clipId: managedObject.clipId,
                               clipIndex: managedObject.clipIndex,
                               imageFileName: managedObject.imageFileName,
                               imageUrl: imageUrl,
                               imageSize: ImageSize(height: managedObject.imageHeight,
                                                    width: managedObject.imageWidth),
                               registeredDate: managedObject.registeredAt,
                               updatedDate: managedObject.updatedAt)
    }
}
