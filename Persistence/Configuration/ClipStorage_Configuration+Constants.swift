//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import RealmSwift

extension TemporaryClipStorage.Configuration {
    public enum Kind {
        case group
    }

    public static func resolve(for bundle: Bundle, kind: Kind) -> Self {
        let realmFileName = self.resolveRealmFileName(for: kind)
        var configuration = self.resolveRealmConfiguration(for: kind)
        configuration.fileURL = self.resolveUrl(for: bundle, realmFileName: realmFileName, kind: kind)
        return .init(realmConfiguration: configuration)
    }

    private static func resolveRealmFileName(for kind: Kind) -> String {
        switch kind {
        case .group:
            return "temporary-clips.realm"
        }
    }

    private static func resolveRealmConfiguration(for kind: Kind) -> Realm.Configuration {
        switch kind {
        case .group:
            return Realm.Configuration(
                schemaVersion: 0,
                migrationBlock: ClipStorageMigrationService.migrationBlock,
                deleteRealmIfMigrationNeeded: false,
                objectTypes: [
                    ClipObject.self,
                    ClipItemObject.self,
                    TagObject.self
                ]
            )
        }
    }

    private static func resolveUrl(for bundle: Bundle, realmFileName: String, kind: Kind) -> URL {
        guard let bundleIdentifier = bundle.bundleIdentifier else {
            fatalError("Failed to resolve bundle identifier")
        }

        switch kind {
        case .group:
            guard let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.\(bundleIdentifier)") else {
                fatalError("Failed to resolve images containing directory url.")
            }
            return directory
                .appendingPathComponent(bundleIdentifier, isDirectory: true)
                .appendingPathComponent(realmFileName)
        }
    }
}
