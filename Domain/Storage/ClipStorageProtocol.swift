//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum ClipStorageError: Error {
    case duplicated
    case notFound
    case invalidParameter
    case internalError
}

public protocol ClipStorageProtocol {
    // MARK: Create

    func create(clip: Clip, withData data: [(URL, Data)], forced: Bool) -> Result<Void, ClipStorageError>

    func create(tagWithName name: String) -> Result<Tag, ClipStorageError>

    func create(albumWithTitle: String) -> Result<Album, ClipStorageError>

    // MARK: Read

    func read(clipOfUrl url: URL) -> Result<Clip, ClipStorageError>

    func read(imageDataOfUrl url: URL, forClipOfUrl clipUrl: URL) -> Result<Data, ClipStorageError>

    func readAllClips() -> Result<[Clip], ClipStorageError>

    func readAllAlbums() -> Result<[Album], ClipStorageError>

    func search(clipsByKeywords: [String]) -> Result<[Clip], ClipStorageError>

    func search(clipsByTags tags: [String]) -> Result<[Clip], ClipStorageError>

    // MARK: Update

    func update(clipByAddingTag tag: String, to clip: Clip) -> Result<Clip, ClipStorageError>

    func update(clipByDeletingTag tag: String, to clip: Clip) -> Result<Clip, ClipStorageError>

    func update(clipItemsInClip clip: Clip, to items: [ClipItem]) -> Result<Clip, ClipStorageError>

    func update(byAddingClip clipUrl: URL, toAlbum album: Album) -> Result<Void, ClipStorageError>

    func update(byAddingClips clipUrls: [URL], toAlbum album: Album) -> Result<Void, ClipStorageError>

    func update(byDeletingClips clipUrls: [URL], fromAlbum album: Album) -> Result<Void, ClipStorageError>

    func update(clipsOfAlbum album: Album, byReplacingWith clips: [Clip]) -> Result<Album, ClipStorageError>

    func update(titleOfAlbum album: Album, to title: String) -> Result<Album, ClipStorageError>

    // MARK: Delete

    func delete(clip: Clip) -> Result<Clip, ClipStorageError>

    func delete(clips: [Clip]) -> Result<[Clip], ClipStorageError>

    func delete(clipItem: ClipItem) -> Result<ClipItem, ClipStorageError>

    func delete(album: Album) -> Result<Album, ClipStorageError>

    func delete(tag: String) -> Result<Tag, ClipStorageError>
}

extension ClipStorageProtocol {
    public func create(clip: Clip, withData data: [(URL, Data)]) -> Result<Void, ClipStorageError> {
        self.create(clip: clip, withData: data, forced: false)
    }
}
