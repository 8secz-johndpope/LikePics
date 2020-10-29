//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

/// @mockable
public protocol ImageStorageProtocol {
    func imageFileExists(named name: String, inClipHaving clipId: Clip.Identity) -> Bool
    func save(_ image: Data, asName fileName: String, inClipHaving clipId: Clip.Identity) throws
    func delete(fileName: String, inClipHaving clipId: Clip.Identity) throws
    func deleteAll(inClipHaving clipId: Clip.Identity) throws
    func readImage(named name: String, inClipHaving clipId: Clip.Identity) throws -> Data?
    func resolveImageFileUrl(named name: String, inClipHaving clipId: Clip.Identity) throws -> URL?
}
