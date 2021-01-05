//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension Persistence.Clip {
    func map(to type: Domain.Clip.Type) -> Domain.Clip? {
        guard let id = self.id,
            let createdDate = self.createdDate,
            let updatedDate = self.updatedDate
        else {
            return nil
        }

        let tags = self.tags?.allObjects
            .compactMap { $0 as? Persistence.Tag }
            .compactMap { $0.map(to: Domain.Tag.self) } ?? []

        let items = self.clipItems?
            .compactMap { $0 as? Persistence.Item }
            .compactMap { $0.map(to: Domain.ClipItem.self) } ?? []

        return Domain.Clip(id: id,
                           description: self.descriptionText,
                           items: items,
                           tags: tags,
                           isHidden: self.isHidden,
                           dataSize: Int(self.imagesSize),
                           registeredDate: createdDate,
                           updatedDate: updatedDate)
    }
}
