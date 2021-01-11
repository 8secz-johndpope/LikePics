//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import UIKit

protocol ClipPreviewViewModelType {
    var inputs: ClipPreviewViewModelInputs { get }
    var outputs: ClipPreviewViewModelOutputs { get }
}

protocol ClipPreviewViewModelInputs {
    var viewWillAppear: PassthroughSubject<Void, Never> { get }
    var viewDidAppear: PassthroughSubject<Void, Never> { get }
}

protocol ClipPreviewViewModelOutputs {
    var itemIdValue: ClipItem.Identity { get }
    var itemUrlValue: URL? { get }

    var loadImage: PassthroughSubject<UIImage, Never> { get }
    var dismiss: PassthroughSubject<Void, Never> { get }
    var displayErrorMessage: PassthroughSubject<String, Never> { get }

    func readInitialImage() -> UIImage?
}

class ClipPreviewViewModel: ClipPreviewViewModelType,
    ClipPreviewViewModelInputs,
    ClipPreviewViewModelOutputs
{
    enum ImageLoadingState {
        case loading
        case thumbnailLoaded
        case imageLoaded

        var isInitialState: Bool {
            switch self {
            case .loading:
                return true

            default:
                return false
            }
        }

        var isAlreadyImageLoaded: Bool {
            switch self {
            case .imageLoaded:
                return true

            default:
                return false
            }
        }
    }

    enum LifeCycleEvent {
        case viewWillAppear
        case viewDidAppear
    }

    // MARK: - Properties

    // MARK: ClipPreviewViewModelType

    var inputs: ClipPreviewViewModelInputs { self }
    var outputs: ClipPreviewViewModelOutputs { self }

    // MARK: ClipPreviewViewModelInputs

    let viewWillAppear: PassthroughSubject<Void, Never> = .init()
    let viewDidAppear: PassthroughSubject<Void, Never> = .init()

    // MARK: ClipPreviewViewModelOutputs

    var itemIdValue: ClipItem.Identity { _item.value.id }
    var itemUrlValue: URL? { _item.value.url }

    let loadImage: PassthroughSubject<UIImage, Never> = .init()
    let dismiss: PassthroughSubject<Void, Never> = .init()
    let displayErrorMessage: PassthroughSubject<String, Never> = .init()

    // MARK: Privates

    private let _item: CurrentValueSubject<ClipItem, Never>

    private let query: ClipItemQuery
    private let imageQueryService: ImageQueryServiceProtocol
    private let logger: TBoxLoggable
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.ClipPreviewViewModel")

    private var state: ImageLoadingState = .loading
    private var preferredLazyLoadTiming: LifeCycleEvent = .viewWillAppear

    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(query: ClipItemQuery,
         imageQueryService: ImageQueryServiceProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.imageQueryService = imageQueryService
        self.logger = logger

        self._item = .init(query.clipItem.value)

        self.bind()
    }

    // MARK: - Methods

    func readInitialImage() -> UIImage? {
        self.readInitialImage(for: self._item.value)
    }

    private func readInitialImage(for item: ClipItem) -> UIImage? {
        return self.queue.sync {
            guard self.state.isInitialState else { return nil }

            // TODO: パフォーマンスの改善
            guard let data = try? self.imageQueryService.read(having: item.imageId),
                let image = UIImage(data: data)
            else {
                self.displayErrorMessage.send(L10n.clipPreviewErrorAtLoadImage)
                return nil
            }
            self.state = .imageLoaded
            return image
        }
    }

    private func lazyReadImageIfNeeded(for item: ClipItem, at event: LifeCycleEvent) {
        guard !self.state.isAlreadyImageLoaded, event == self.preferredLazyLoadTiming else { return }
        guard let data = try? self.imageQueryService.read(having: item.imageId),
            let image = UIImage(data: data)
        else {
            self.displayErrorMessage.send(L10n.clipPreviewErrorAtLoadImage)
            return
        }
        self.queue.sync {
            self.state = .imageLoaded
        }
        self.loadImage.send(image)
    }
}

extension ClipPreviewViewModel {
    // MARK: - Bind

    private func bind() {
        self.bindInputs()
        self.bindOutputs()
    }

    private func bindInputs() {
        self.viewWillAppear
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.lazyReadImageIfNeeded(for: self._item.value, at: .viewWillAppear)
            }
            .store(in: &self.cancellableBag)

        self.viewDidAppear
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.lazyReadImageIfNeeded(for: self._item.value, at: .viewDidAppear)
            }
            .store(in: &self.cancellableBag)
    }

    private func bindOutputs() {
        self.query.clipItem
            .sink { [weak self] _ in
                self?.dismiss.send(())
            } receiveValue: { [weak self] item in
                self?._item.send(item)
            }
            .store(in: &self.cancellableBag)
    }
}
