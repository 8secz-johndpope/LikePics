//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable force_cast force_unwrapping

import CoreData
import Domain

public class NewClipStorage {
    private let masterContext: NSManagedObjectContext
    private let context: NSManagedObjectContext

    public init(masterContext: NSManagedObjectContext,
                context: NSManagedObjectContext)
    {
        self.masterContext = masterContext
        self.context = context
    }
}

extension NewClipStorage: ClipStorageProtocol {
    public var isInTransaction: Bool {
        return self.context.hasChanges
    }

    public func beginTransaction() throws {
        // NOP
    }

    public func commitTransaction() throws {
        try self.context.save()
        if Thread.isMainThread {
            try self.masterContext.save()
        } else {
            try DispatchQueue.main.sync {
                try self.masterContext.save()
            }
        }
    }

    public func cancelTransactionIfNeeded() throws {
        self.context.rollback()
    }

    public func readAllClips() -> Result<[Domain.Clip], ClipStorageError> {
        do {
            let request = NSFetchRequest<Clip>(entityName: "Clip")
            let clips = try self.context.fetch(request)
                .compactMap { $0.map(to: Domain.Clip.self) }
            return .success(clips)
        } catch {
            return .failure(.internalError)
        }
    }

    public func readAllTags() -> Result<[Domain.Tag], ClipStorageError> {
        do {
            let request = NSFetchRequest<Tag>(entityName: "Tag")
            let tags = try self.context.fetch(request)
                .compactMap { $0.map(to: Domain.Tag.self) }
            return .success(tags)
        } catch {
            return .failure(.internalError)
        }
    }

    public func create(clip: Domain.Clip, allowTagCreation: Bool, overwrite: Bool) -> Result<Domain.Clip, ClipStorageError> {
        do {
            // Check parameters

            var appendingTags: [Tag] = []
            for tag in clip.tags {
                let request = NSFetchRequest<Tag>(entityName: "Tag")
                request.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
                if let tag = try self.context.fetch(request).first {
                    appendingTags.append(tag)
                } else {
                    guard allowTagCreation else {
                        return .failure(.invalidParameter)
                    }
                    let newTag = NSEntityDescription.insertNewObject(forEntityName: "Tag",
                                                                     into: self.context) as! Tag
                    newTag.id = UUID(uuidString: tag.id)!
                    newTag.name = tag.name
                    newTag.isHidden = false
                    appendingTags.append(newTag)
                }
            }

            // Check duplication

            var oldClip: Clip?
            let request = NSFetchRequest<Clip>(entityName: "Clip")
            request.predicate = NSPredicate(format: "id == %@", clip.id as CVarArg)
            if let duplicatedClip = try self.context.fetch(request).first {
                if overwrite {
                    oldClip = duplicatedClip
                } else {
                    return .failure(.duplicated)
                }
            }

            // Prepare new objects

            let newClip = NSEntityDescription.insertNewObject(forEntityName: "Clip",
                                                              into: self.context) as! Clip
            newClip.id = UUID(uuidString: clip.id)!
            newClip.descriptionText = clip.description

            let items: NSMutableOrderedSet = .init()
            clip.items.forEach { item in
                let newItem = NSEntityDescription.insertNewObject(forEntityName: "Item",
                                                                  into: self.context) as! Item
                newItem.id = UUID(uuidString: item.id)!
                newItem.siteUrl = item.url
                newItem.clipId = UUID(uuidString: clip.id)!
                newItem.index = Int64(item.clipIndex)
                newItem.imageFileName = item.imageFileName
                newItem.imageUrl = item.imageUrl
                newItem.imageHeight = item.imageSize.height
                newItem.imageWidth = item.imageSize.width
                newItem.createdDate = item.registeredDate
                newItem.updatedDate = item.updatedDate

                items.add(newItem)
            }
            newClip.items = items
            newClip.tags = NSSet(array: appendingTags)

            newClip.isHidden = clip.isHidden
            newClip.createdDate = clip.registeredDate
            newClip.updatedDate = clip.updatedDate

            // Delete

            oldClip?.items?
                .compactMap { $0 as? Item }
                .forEach { item in
                    self.context.delete(item)
                }

            return .success(newClip.map(to: Domain.Clip.self)!)
        } catch {
            return .failure(.internalError)
        }
    }

    public func create(tagWithName name: String) -> Result<Domain.Tag, ClipStorageError> {
        do {
            let request = NSFetchRequest<Tag>(entityName: "Tag")
            request.predicate = NSPredicate(format: "name == %@", name as CVarArg)
            guard try self.context.fetch(request).first == nil else {
                return .failure(.duplicated)
            }

            let tag = NSEntityDescription.insertNewObject(forEntityName: "Tag",
                                                          into: self.context) as! Tag
            tag.id = UUID()
            tag.name = name
            tag.isHidden = false

            return .success(tag.map(to: Domain.Tag.self)!)
        } catch {
            return .failure(.internalError)
        }
    }

    public func create(albumWithTitle title: String) -> Result<Domain.Album, ClipStorageError> {
        do {
            let request = NSFetchRequest<Tag>(entityName: "Album")
            request.predicate = NSPredicate(format: "title == %@", title as CVarArg)
            guard try self.context.fetch(request).first == nil else {
                return .failure(.duplicated)
            }

            let album = NSEntityDescription.insertNewObject(forEntityName: "Album",
                                                            into: self.context) as! Album
            album.id = UUID()
            album.title = title
            album.createdDate = Date()
            album.updatedDate = Date()
            album.isHidden = false

            return .success(album.map(to: Domain.Album.self)!)
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateClips(having ids: [Domain.Clip.Identity], byHiding: Bool) -> Result<[Domain.Clip], ClipStorageError> {
        return .failure(.internalError)
    }

    public func updateClips(having clipIds: [Domain.Clip.Identity], byAddingTagsHaving tagIds: [Domain.Tag.Identity]) -> Result<[Domain.Clip], ClipStorageError> {
        return .failure(.internalError)
    }

    public func updateClips(having clipIds: [Domain.Clip.Identity], byDeletingTagsHaving tagIds: [Domain.Tag.Identity]) -> Result<[Domain.Clip], ClipStorageError> {
        return .failure(.internalError)
    }

    public func updateClips(having clipIds: [Domain.Clip.Identity], byReplacingTagsHaving tagIds: [Domain.Tag.Identity]) -> Result<[Domain.Clip], ClipStorageError> {
        return .failure(.internalError)
    }

    public func updateAlbum(having albumId: Domain.Album.Identity, byAddingClipsHaving clipIds: [Domain.Clip.Identity]) -> Result<Void, ClipStorageError> {
        return .failure(.internalError)
    }

    public func updateAlbum(having albumId: Domain.Album.Identity, byDeletingClipsHaving clipIds: [Domain.Clip.Identity]) -> Result<Void, ClipStorageError> {
        return .failure(.internalError)
    }

    public func updateAlbum(having albumId: Domain.Album.Identity, titleTo title: String) -> Result<Domain.Album, ClipStorageError> {
        return .failure(.internalError)
    }

    public func updateTag(having id: Domain.Tag.Identity, nameTo name: String) -> Result<Domain.Tag, ClipStorageError> {
        return .failure(.internalError)
    }

    public func deleteClips(having ids: [Domain.Clip.Identity]) -> Result<[Domain.Clip], ClipStorageError> {
        do {
            var clips: [Clip] = []
            for id in ids {
                let request = NSFetchRequest<Clip>(entityName: "Clip")
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                guard let clip = try self.context.fetch(request).first else {
                    return .failure(.notFound)
                }
                clips.append(clip)
            }
            let deleteTarget = clips.compactMap { $0.map(to: Domain.Clip.self) }

            clips.forEach { self.context.delete($0) }

            return .success(deleteTarget)
        } catch {
            return .failure(.internalError)
        }
    }

    public func deleteClipItem(having id: Domain.ClipItem.Identity) -> Result<Domain.ClipItem, ClipStorageError> {
        do {
            let request = NSFetchRequest<Item>(entityName: "Item")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            guard let item = try self.context.fetch(request).first else {
                return .failure(.notFound)
            }
            let removeTarget = item.map(to: Domain.ClipItem.self)!

            self.context.delete(item)
            item.clip?.items?
                .compactMap { $0 as? Item }
                .sorted(by: { $0.index < $1.index })
                .enumerated()
                .forEach { $0.element.index = Int64($0.offset) }

            return .success(removeTarget)
        } catch {
            return .failure(.internalError)
        }
    }

    public func deleteAlbum(having id: Domain.Album.Identity) -> Result<Domain.Album, ClipStorageError> {
        do {
            let request = NSFetchRequest<Album>(entityName: "Album")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            guard let album = try self.context.fetch(request).first else {
                return .failure(.notFound)
            }
            let deleteTarget = album.map(to: Domain.Album.self)!

            self.context.delete(album)

            return .success(deleteTarget)
        } catch {
            return .failure(.internalError)
        }
    }

    public func deleteTags(having ids: [Domain.Tag.Identity]) -> Result<[Domain.Tag], ClipStorageError> {
        do {
            var tags: [Tag] = []
            for id in ids {
                let request = NSFetchRequest<Tag>(entityName: "Tag")
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                guard let tag = try self.context.fetch(request).first else {
                    return .failure(.notFound)
                }
                tags.append(tag)
            }
            let deleteTarget = tags.compactMap { $0.map(to: Domain.Tag.self) }

            tags.forEach { self.context.delete($0) }

            return .success(deleteTarget)
        } catch {
            return .failure(.internalError)
        }
    }

    public func deleteAll() -> Result<Void, ClipStorageError> {
        return .failure(.internalError)
    }
}
