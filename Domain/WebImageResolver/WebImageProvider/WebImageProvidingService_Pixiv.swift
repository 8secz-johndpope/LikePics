//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Erik
import PromiseKit

extension WebImageProvidingService {
    public enum Pixiv: WebImageProvider {
        // MARK: - WebImageProvider

        public static func isProviding(url: URL) -> Bool {
            guard let host = url.host else { return false }
            return host.contains("pximg")
        }

        public static func modifyUrlForProcessing(_ url: URL) -> URL {
            return url
        }

        public static func shouldPreprocess(for url: URL) -> Bool {
            return false
        }

        public static func preprocess(_ browser: Erik, document: Document) -> Promise<Document> {
            return Promise { $0.resolve(.fulfilled(document)) }
        }

        public static func resolveLowQualityImageUrl(of url: URL) -> URL? {
            return nil
        }

        public static func resolveHighQualityImageUrl(of url: URL) -> URL? {
            return nil
        }

        public static func shouldModifyRequest(for url: URL) -> Bool {
            return true
        }

        public static func modifyRequest(_ request: URLRequest) -> URLRequest {
            var req = request
            req.setValue("http://www.pixiv.net/", forHTTPHeaderField: "Referer")
            return req
        }
    }
}
