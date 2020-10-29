///
/// @Generated by Mockolo
///

import Domain
@testable import Persistence
import RealmSwift

public class ImageStorageProtocolMock: ImageStorageProtocol {
    public init() { }

    public private(set) var imageFileExistsCallCount = 0
    public var imageFileExistsHandler: ((String, Clip.Identity) -> (Bool))?
    public func imageFileExists(named name: String, inClipHaving clipId: Clip.Identity) -> Bool {
        imageFileExistsCallCount += 1
        if let imageFileExistsHandler = imageFileExistsHandler {
            return imageFileExistsHandler(name, clipId)
        }
        return false
    }

    public private(set) var saveCallCount = 0
    public var saveHandler: ((Data, String, Clip.Identity) throws -> Void)?
    public func save(_ image: Data, asName fileName: String, inClipHaving clipId: Clip.Identity) throws {
        saveCallCount += 1
        if let saveHandler = saveHandler {
            try saveHandler(image, fileName, clipId)
        }
    }

    public private(set) var deleteCallCount = 0
    public var deleteHandler: ((String, Clip.Identity) throws -> Void)?
    public func delete(fileName: String, inClipHaving clipId: Clip.Identity) throws {
        deleteCallCount += 1
        if let deleteHandler = deleteHandler {
            try deleteHandler(fileName, clipId)
        }
    }

    public private(set) var deleteAllCallCount = 0
    public var deleteAllHandler: ((Clip.Identity) throws -> Void)?
    public func deleteAll(inClipHaving clipId: Clip.Identity) throws {
        deleteAllCallCount += 1
        if let deleteAllHandler = deleteAllHandler {
            try deleteAllHandler(clipId)
        }
    }

    public private(set) var readImageCallCount = 0
    public var readImageHandler: ((String, Clip.Identity) throws -> (Data))?
    public func readImage(named name: String, inClipHaving clipId: Clip.Identity) throws -> Data {
        readImageCallCount += 1
        if let readImageHandler = readImageHandler {
            return try readImageHandler(name, clipId)
        }
        fatalError("readImageHandler returns can't have a default value thus its handler must be set")
    }

    public private(set) var resolveImageFileUrlCallCount = 0
    public var resolveImageFileUrlHandler: ((String, Clip.Identity) throws -> (URL))?
    public func resolveImageFileUrl(named name: String, inClipHaving clipId: Clip.Identity) throws -> URL {
        resolveImageFileUrlCallCount += 1
        if let resolveImageFileUrlHandler = resolveImageFileUrlHandler {
            return try resolveImageFileUrlHandler(name, clipId)
        }
        return URL(fileURLWithPath: "")
    }
}
