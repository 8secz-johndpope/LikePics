//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import Persistence
import TBoxCore
import TBoxUIKit
import UIKit

protocol ViewControllerFactory {
    // MARK: Top

    func makeTopClipsListViewController() -> UIViewController?

    // MARK: Preview

    func makeClipPreviewViewController(clipId: Domain.Clip.Identity) -> UIViewController?
    func makeClipItemPreviewViewController(clipId: Domain.Clip.Identity, itemId: ClipItem.Identity) -> ClipItemPreviewViewController?

    // MARK: Information

    func makeClipInformationViewController(clipId: Domain.Clip.Identity,
                                           itemId: ClipItem.Identity,
                                           transitioningController: ClipInformationTransitioningControllerProtocol,
                                           dataSource: ClipInformationViewDataSource) -> UIViewController?

    // MARK: Selection

    func makeClipTargetCollectionViewController(clipUrl: URL, delegate: ClipTargetFinderDelegate, isOverwrite: Bool) -> UIViewController

    // MARK: Search

    func makeSearchEntryViewController() -> UIViewController
    func makeSearchResultViewController(context: SearchContext) -> UIViewController?

    // MARK: Album

    func makeAlbumListViewController() -> UIViewController?
    func makeAlbumViewController(albumId: Domain.Album.Identity) -> UIViewController?
    func makeAlbumSelectionViewController(context: Any?, delegate: AlbumSelectionPresenterDelegate) -> UIViewController?

    // MARK: Tag

    func makeTagListViewController() -> UIViewController?
    func makeTagSelectionViewController(selectedTags: [Domain.Tag.Identity], context: Any?, delegate: TagSelectionPresenterDelegate) -> UIViewController?

    // MARK: Settings

    func makeSettingsViewController() -> UIViewController
}

class DependencyContainer {
    private let clipQueryService: ClipQueryServiceProtocol
    private let clipCommandService: ClipCommandServiceProtocol
    private let clipViewer: ClipViewable
    private let clipStore: ClipStorable
    private let imageStorage: ImageStorageProtocol
    private let thumbnailStorage: ThumbnailStorageProtocol
    private let logger: TBoxLoggable
    private let userSettingsStorage = UserSettingsStorage()

    private let clipCommandQueue = DispatchQueue(label: "net.tasuwo.TBox.ClipCommand")

    let persistService: TemporaryClipsPersistServiceProtocol
    let integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol

    init() throws {
        let thumbnailStorage = try ThumbnailStorage()
        let imageStorage = try ImageStorage(configuration: .document)
        let tmpImageStorage = try ImageStorage(configuration: .group)
        let logger = RootLogger.shared
        let clipStorage = try ClipStorage(config: .appSupport, logger: logger)
        let tmpClipStorage = try ClipStorage(config: .group, logger: logger)
        let referenceClipStorage = try ReferenceClipStorage(config: .group, logger: logger)
        let clipCommandService = ClipCommandService(clipStorage: clipStorage,
                                                    referenceClipStorage: referenceClipStorage,
                                                    imageStorage: imageStorage,
                                                    thumbnailStorage: thumbnailStorage,
                                                    logger: logger,
                                                    queue: self.clipCommandQueue)
        self.clipQueryService = clipStorage
        self.clipCommandService = clipCommandService
        self.clipViewer = clipStorage
        self.clipStore = clipCommandService
        self.imageStorage = imageStorage
        self.thumbnailStorage = thumbnailStorage
        self.logger = logger
        self.persistService = TemporaryClipsPersistService(temporaryClipStorage: tmpClipStorage,
                                                           temporaryImageStorage: tmpImageStorage,
                                                           clipStorage: clipStorage,
                                                           referenceClipStorage: referenceClipStorage,
                                                           imageStorage: imageStorage,
                                                           logger: logger,
                                                           queue: self.clipCommandQueue)
        self.integrityValidationService = ClipReferencesIntegrityValidationService(clipStorage: clipStorage,
                                                                                   referenceClipStorage: referenceClipStorage,
                                                                                   logger: logger,
                                                                                   queue: self.clipCommandQueue)
    }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeTopClipsListViewController() -> UIViewController? {
        let query: ClipListQuery
        switch self.clipQueryService.queryAllClips() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open TopClipsListView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = TopClipsListPresenter(query: query,
                                              clipService: self.clipCommandService,
                                              cacheStorage: self.thumbnailStorage,
                                              settingStorage: self.userSettingsStorage,
                                              logger: self.logger)

        let navigationItemsPresenter = ClipsListNavigationItemsPresenter(dataSource: presenter)
        let navigationItemsProvider = ClipsListNavigationItemsProvider(presenter: navigationItemsPresenter)

        let toolBarItemsPresenter = ClipsListToolBarItemsPresenter(target: .top, dataSource: presenter)
        let toolBarItemsProvider = ClipsListToolBarItemsProvider(presenter: toolBarItemsPresenter)

        let viewController = TopClipsListViewController(factory: self,
                                                        presenter: presenter,
                                                        clipsListCollectionViewProvider: ClipsListCollectionViewProvider(),
                                                        navigationItemsProvider: navigationItemsProvider,
                                                        toolBarItemsProvider: toolBarItemsProvider)

        return UINavigationController(rootViewController: viewController)
    }

    func makeClipPreviewViewController(clipId: Domain.Clip.Identity) -> UIViewController? {
        let query: ClipQuery
        switch self.clipQueryService.queryClip(having: clipId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipPreviewView for clip having clip id \(clipId). (\(error.rawValue))
            """))
            return nil
        }

        let presenter = ClipPreviewPagePresenter(query: query,
                                                 clipCommandService: self.clipCommandService,
                                                 logger: self.logger)

        let barItemsPresenter = ClipPreviewPageBarButtonItemsPresenter(dataSource: presenter)
        let barItemsProvider = ClipPreviewPageBarButtonItemsProvider(presenter: barItemsPresenter)

        let previewTransitioningController = ClipPreviewTransitioningController(logger: self.logger)
        let informationTransitioningController = ClipInformationTransitioningController(logger: self.logger)

        let pageViewController = ClipPreviewPageViewController(
            factory: self,
            presenter: presenter,
            barItemsProvider: barItemsProvider,
            previewTransitioningController: previewTransitioningController,
            informationTransitionController: informationTransitioningController
        )

        let viewController = ClipPreviewViewController(pageViewController: pageViewController)
        viewController.transitioningDelegate = previewTransitioningController
        viewController.modalPresentationStyle = .fullScreen

        return viewController
    }

    func makeClipItemPreviewViewController(clipId: Domain.Clip.Identity, itemId: ClipItem.Identity) -> ClipItemPreviewViewController? {
        let query: ClipQuery
        switch self.clipQueryService.queryClip(having: clipId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipItemPreviewView for clip having clip id \(clipId), item id \(itemId). (\(error.rawValue))
            """))
            return nil
        }

        let presenter = ClipItemPreviewPresenter(query: query,
                                                 itemId: itemId,
                                                 imageStorage: self.imageStorage,
                                                 thumbnailStorage: self.thumbnailStorage,
                                                 logger: self.logger)

        let viewController = ClipItemPreviewViewController(factory: self, presenter: presenter)

        return viewController
    }

    func makeClipInformationViewController(clipId: Domain.Clip.Identity,
                                           itemId: ClipItem.Identity,
                                           transitioningController: ClipInformationTransitioningControllerProtocol,
                                           dataSource: ClipInformationViewDataSource) -> UIViewController?
    {
        let query: ClipQuery
        switch self.clipQueryService.queryClip(having: clipId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipInformationPresenter for clip having clip id \(clipId), item id \(itemId). (\(error.rawValue))
            """))
            return nil
        }

        let presenter = ClipInformationPresenter(query: query,
                                                 itemId: itemId,
                                                 clipCommandService: self.clipCommandService,
                                                 logger: self.logger)

        let viewController = ClipInformationViewController(factory: self,
                                                           dataSource: dataSource,
                                                           presenter: presenter,
                                                           transitioningController: transitioningController)
        viewController.transitioningDelegate = transitioningController
        viewController.modalPresentationStyle = .fullScreen
        return viewController
    }

    func makeClipTargetCollectionViewController(clipUrl: URL, delegate: ClipTargetFinderDelegate, isOverwrite: Bool) -> UIViewController {
        let presenter = ClipTargetFinderPresenter(url: clipUrl,
                                                  clipStore: self.clipStore,
                                                  clipViewer: self.clipViewer,
                                                  currentDateResolver: { Date() },
                                                  isEnabledOverwrite: isOverwrite)
        let viewController = ClipTargetFinderViewController(presenter: presenter, delegate: delegate)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchEntryViewController() -> UIViewController {
        let presenter = SearchEntryPresenter()
        let viewController = SearchEntryViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchResultViewController(context: SearchContext) -> UIViewController? {
        let query: ClipListQuery
        switch context {
        case let .keywords(values):
            switch self.clipQueryService.queryClips(matchingKeywords: values) {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for keywords \(values). (\(error.rawValue))
                """))
                return nil
            }

        case let .tag(value):
            switch self.clipQueryService.queryClips(tagged: value) {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for tag \(value). (\(error.rawValue))
                """))
                return nil
            }

        case .uncategorized:
            switch self.clipQueryService.queryUncategorizedClips() {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for uncategorized clips. (\(error.rawValue))
                """))
                return nil
            }
        }

        let presenter = SearchResultPresenter(context: context,
                                              query: query,
                                              clipCommandService: self.clipCommandService,
                                              cacheStorage: self.thumbnailStorage,
                                              settingStorage: self.userSettingsStorage,
                                              logger: self.logger)

        let navigationItemsPresenter = ClipsListNavigationItemsPresenter(dataSource: presenter)
        let navigationItemsProvider = ClipsListNavigationItemsProvider(presenter: navigationItemsPresenter)

        let toolBarItemsPresenter = ClipsListToolBarItemsPresenter(target: .searchResult, dataSource: presenter)
        let toolBarItemsProvider = ClipsListToolBarItemsProvider(presenter: toolBarItemsPresenter)

        return SearchResultViewController(factory: self,
                                          presenter: presenter,
                                          clipsListCollectionViewProvider: ClipsListCollectionViewProvider(),
                                          navigationItemsProvider: navigationItemsProvider,
                                          toolBarItemsProvider: toolBarItemsProvider)
    }

    func makeAlbumListViewController() -> UIViewController? {
        let query: AlbumListQuery
        switch self.clipQueryService.queryAllAlbums() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open AlbumListView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = AlbumListPresenter(query: query,
                                           clipCommandService: self.clipCommandService,
                                           thumbnailStorage: self.thumbnailStorage,
                                           settingStorage: self.userSettingsStorage,
                                           logger: self.logger)

        let viewController = AlbumListViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeAlbumViewController(albumId: Domain.Album.Identity) -> UIViewController? {
        let query: AlbumQuery
        switch self.clipQueryService.queryAlbum(having: albumId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open AlbumView for album having id \(albumId). (\(error.rawValue))
            """))
            return nil
        }

        let presenter = AlbumPresenter(query: query,
                                       clipCommandService: self.clipCommandService,
                                       thumbnailStorage: self.thumbnailStorage,
                                       settingStorage: self.userSettingsStorage,
                                       logger: self.logger)

        let navigationItemsPresenter = ClipsListNavigationItemsPresenter(dataSource: presenter)
        let navigationItemsProvider = ClipsListNavigationItemsProvider(presenter: navigationItemsPresenter)

        let toolBarItemsPresenter = ClipsListToolBarItemsPresenter(target: .album, dataSource: presenter)
        let toolBarItemsProvider = ClipsListToolBarItemsProvider(presenter: toolBarItemsPresenter)

        return AlbumViewController(factory: self,
                                   presenter: presenter,
                                   clipsListCollectionViewProvider: ClipsListCollectionViewProvider(),
                                   navigationItemsProvider: navigationItemsProvider,
                                   toolBarItemsProvider: toolBarItemsProvider)
    }

    func makeAlbumSelectionViewController(context: Any?, delegate: AlbumSelectionPresenterDelegate) -> UIViewController? {
        let query: AlbumListQuery
        switch self.clipQueryService.queryAllAlbums() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open AlbumSelectionView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = AlbumSelectionPresenter(query: query,
                                                context: context,
                                                clipCommandService: self.clipCommandService,
                                                thumbnailStorage: self.thumbnailStorage,
                                                settingStorage: self.userSettingsStorage,
                                                logger: self.logger)
        presenter.delegate = delegate
        let viewController = AlbumSelectionViewController(factory: self, presenter: presenter)

        return UINavigationController(rootViewController: viewController)
    }

    func makeTagListViewController() -> UIViewController? {
        let query: TagListQuery
        switch self.clipQueryService.queryAllTags() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open TagSelectionView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = TagListPresenter(query: query,
                                         clipCommandService: self.clipCommandService,
                                         logger: self.logger)
        let viewController = TagListViewController(factory: self, presenter: presenter, logger: self.logger)

        return UINavigationController(rootViewController: viewController)
    }

    func makeTagSelectionViewController(selectedTags: [Domain.Tag.Identity],
                                        context: Any?,
                                        delegate: TagSelectionPresenterDelegate) -> UIViewController?
    {
        let query: TagListQuery
        switch self.clipQueryService.queryAllTags() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open TagSelectionView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = TagSelectionPresenter(query: query,
                                              selectedTags: selectedTags,
                                              context: context,
                                              clipCommandService: self.clipCommandService,
                                              logger: self.logger)
        presenter.delegate = delegate
        let viewController = TagSelectionViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSettingsViewController() -> UIViewController {
        let storyBoard = UIStoryboard(name: "SettingsViewController", bundle: Bundle.main)

        // swiftlint:disable:next force_cast
        let viewController = storyBoard.instantiateViewController(identifier: "SettingsViewController") as! SettingsViewController

        let presenter = SettingsPresenter(storage: self.userSettingsStorage)
        viewController.factory = self
        viewController.presenter = presenter

        return viewController
    }
}

extension ClipCommandService: ClipStorable {}
extension ClipStorage: ClipViewable {
    // MARK: - ClipViewable

    public func clip(havingUrl url: URL) -> Result<TransferringClip?, Error> {
        switch self.readClip(havingUrl: url) {
        case .success(.none):
            return .success(nil)

        case let .success(.some(clip)):
            return .success(.init(id: clip.id,
                                  description: clip.description,
                                  tags: clip.tags.map {
                                      TransferringClip.Tag(id: $0.id, name: $0.name)
                                  },
                                  isHidden: clip.isHidden,
                                  registeredDate: clip.registeredDate))

        case let .failure(error):
            return .failure(error)
        }
    }
}
