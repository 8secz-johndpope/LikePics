//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataAlbumListQuery: NSObject {
    private var albumIds: Set<Domain.Album.Identity>
    private var subject: CurrentValueSubject<[Domain.Album], Error>
    private let controller: NSFetchedResultsController<Album>

    // MARK: - Lifecycle

    init(request: NSFetchRequest<Album>, context: NSManagedObjectContext) throws {
        let currentAlbums = try context.fetch(request)
            .compactMap { $0.map(to: Domain.Album.self) }

        self.albumIds = Set(currentAlbums.map({ $0.id }))
        self.subject = .init(currentAlbums)
        self.controller = NSFetchedResultsController(fetchRequest: request,
                                                     managedObjectContext: context,
                                                     sectionNameKeyPath: nil,
                                                     cacheName: nil)

        super.init()

        self.controller.delegate = self
        try self.controller.performFetch()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contextDidChangeNotification(notification:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: context)
    }

    // MARK: - Methods

    @objc
    private func contextDidChangeNotification(notification: NSNotification) {
        guard let context = notification.object as? NSManagedObjectContext else { return }
        context.perform { [weak self] in
            guard let self = self else { return }
            if let objects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> {
                // AlbumItemの更新を検知する
                if let objects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> {
                    for albumItem in objects.compactMap({ $0 as? AlbumItem }) {
                        if let album = albumItem.album, let albumId = album.id, self.albumIds.contains(albumId) {
                            context.refresh(album, mergeChanges: true)
                            return
                        }
                    }
                }

                // Clipの更新を検知する
                for clip in objects.compactMap({ $0 as? Clip }) {
                    if let albumItem = clip.albumItem?
                        .allObjects
                        .compactMap({ $0 as? AlbumItem })
                        .first(where: { albumItem in
                            guard let albumId = albumItem.album?.id else { return false }
                            return self.albumIds.contains(albumId)
                        }),
                        let album = albumItem.album
                    {
                        context.refresh(album, mergeChanges: true)
                        return
                    }
                }
            }
        }
    }
}

extension CoreDataAlbumListQuery: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    {
        controller.managedObjectContext.perform { [weak self] in
            guard let self = self else { return }
            let albums: [Domain.Album] = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
                .compactMap { controller.managedObjectContext.object(with: $0) as? Album }
                .compactMap { $0.map(to: Domain.Album.self) }
            self.albumIds = Set(albums.map { $0.id })
            self.subject.send(albums)
        }
    }
}

extension CoreDataAlbumListQuery: AlbumListQuery {
    // MARK: - AlbumListQuery

    var albums: CurrentValueSubject<[Domain.Album], Error> {
        return self.subject
    }
}
