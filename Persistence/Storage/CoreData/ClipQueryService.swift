//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain

public class ClipQueryService {
    public var context: NSManagedObjectContext {
        didSet {
            self.observers.forEach { $0.value?.didReplaced(context: self.context) }
        }
    }

    private var observers: [WeakContainer<ViewContextObserver>] = []

    public init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension ClipQueryService: ClipQueryServiceProtocol {
    public func queryClip(having id: Domain.Clip.Identity) -> Result<Domain.ClipQuery, ClipStorageError> {
        do {
            guard let query = try CoreDataClipQuery(id: id, context: self.context) else {
                return .failure(.notFound)
            }
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryAllClips() -> Result<ClipListQuery, ClipStorageError> {
        do {
            let request = NSFetchRequest<Clip>(entityName: "Clip")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Clip.createdDate, ascending: true)]
            let query = try CoreDataClipListQuery(request: request, context: self.context)
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryUncategorizedClips() -> Result<ClipListQuery, ClipStorageError> {
        do {
            let request = NSFetchRequest<Clip>(entityName: "Clip")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Clip.createdDate, ascending: true)]
            request.predicate = NSPredicate(format: "tags.@count == 0")
            let query = try CoreDataClipListQuery(request: request, context: self.context)
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryClips(matchingKeywords keywords: [String]) -> Result<ClipListQuery, ClipStorageError> {
        return .failure(.internalError)
    }

    public func queryClips(tagged tag: Domain.Tag) -> Result<ClipListQuery, ClipStorageError> {
        do {
            let request = NSFetchRequest<Clip>(entityName: "Clip")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Clip.createdDate, ascending: true)]
            request.predicate = NSPredicate(format: "SUBQUERY(tags, $tag, $tag.id == %@).@count > 0", tag.id as CVarArg)
            let query = try CoreDataClipListQuery(request: request, context: self.context)
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryAlbum(having id: Domain.Album.Identity) -> Result<AlbumQuery, ClipStorageError> {
        do {
            guard let query = try CoreDataAlbumQuery(id: id, context: self.context) else {
                return .failure(.notFound)
            }
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryAllAlbums() -> Result<AlbumListQuery, ClipStorageError> {
        do {
            let request = NSFetchRequest<Album>(entityName: "Album")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Album.createdDate, ascending: true)]
            let query = try CoreDataAlbumListQuery(request: request, context: self.context)
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }

    public func queryAllTags() -> Result<TagListQuery, ClipStorageError> {
        do {
            let request = NSFetchRequest<Tag>(entityName: "Tag")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
            let query = try CoreDataTagListQuery(request: request, context: self.context)
            self.observers.append(.init(value: query))
            return .success(query)
        } catch {
            return .failure(.internalError)
        }
    }
}
