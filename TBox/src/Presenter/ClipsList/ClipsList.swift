//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain

struct ClipsList {
    private(set) var clips: [Clip] {
        didSet {
            self.delegate?.clipsListProviding(self, didUpdateClipsTo: self.clips)
        }
    }

    private(set) var selectedClips: [Clip] = [] {
        didSet {
            self.delegate?.clipsListProviding(self, didUpdateSelectedIndicesTo: self.selectedIndices)
        }
    }

    private(set) var isEditing: Bool = false {
        didSet {
            self.delegate?.clipsListProviding(self, didUpdateEditingStateTo: self.isEditing)
        }
    }

    var selectedIndices: [Int] {
        return self.selectedClips.compactMap { selectedClip in
            self.clips.firstIndex(where: { $0.url == selectedClip.url })
        }
    }

    weak var delegate: ClipsListDelegate?

    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    // MARK: - Lifecycle

    init(clips: [Clip], storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.clips = clips
        self.storage = storage
        self.logger = logger
    }
}

extension ClipsList: ClipsListProtocol {
    // MARK: - ClipsListProviding

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data? {
        let nullableClipItem: ClipItem? = {
            switch layer {
            case .primary:
                return clip.primaryItem

            case .secondary:
                return clip.secondaryItem

            case .tertiary:
                return clip.tertiaryItem
            }
        }()
        guard let clipItem = nullableClipItem else { return nil }

        switch self.storage.readImageData(having: clipItem.thumbnail.url, forClipHaving: clip.url) {
        case let .success(data):
            return data

        case let .failure(error):
            self.delegate?.clipsListProviding(self, failedToGetImageDataWith: error)
            return nil
        }
    }

    mutating func set(delegate: ClipsListDelegate) {
        self.delegate = delegate
    }

    mutating func loadAll() {
        switch self.storage.readAllClips() {
        case let .success(clips):
            self.clips = clips.sorted(by: { $0.registeredDate > $1.registeredDate })

        case let .failure(error):
            self.delegate?.clipsListProviding(self, failedToReadClipsWith: error)
        }
    }

    mutating func setEditing(_ editing: Bool) {
        if self.isEditing != editing {
            self.selectedClips = []
        }
        self.isEditing = editing
    }

    mutating func select(at index: Int) {
        guard self.clips.indices.contains(index) else { return }
        let clip = self.clips[index]

        if self.isEditing {
            guard !self.selectedClips.contains(where: { $0.url == clip.url }) else {
                return
            }
            self.selectedClips.append(clip)
        } else {
            self.selectedClips = [clip]
            self.delegate?.clipsListProviding(self, didTapClip: clip, at: index)
        }
    }

    mutating func deselect(at index: Int) {
        guard self.clips.indices.contains(index) else { return }
        let clip = self.clips[index]

        if self.isEditing {
            guard let index = self.selectedClips.firstIndex(where: { $0.url == clip.url }) else {
                return
            }
            self.selectedClips.remove(at: index)
        } else {
            self.selectedClips = []
        }
    }

    mutating func deleteSelectedClips() {
        if case let .failure(error) = self.storage.delete(self.selectedClips) {
            self.delegate?.clipsListProviding(self, failedToDeleteClipsWith: error)
            return
        }

        let newClips: [Clip] = self.clips.compactMap { clip in
            if self.selectedClips.contains(where: { clip.url == $0.url }) { return nil }
            return clip
        }
        self.clips = newClips

        self.selectedClips = []

        self.isEditing = false
    }

    mutating func removeSelectedClips(from album: Album) {
        switch self.storage.update(album, byDeletingClipsHaving: self.selectedClips.map { $0.url }) {
        case .success:
            // NOP
            break

        case let .failure(error):
            self.delegate?.clipsListProviding(self, failedToDeleteClipsWith: error)
            return
        }

        let newClips: [Clip] = self.clips.compactMap { clip in
            if self.selectedClips.contains(where: { clip.url == $0.url }) { return nil }
            return clip
        }
        self.clips = newClips

        self.selectedClips = []

        self.isEditing = false
    }
}
