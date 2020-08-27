//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol ClipPreviewPresentingViewController: UIViewController {
    var collectionView: ClipsCollectionView! { get }
    var selectedIndexPath: IndexPath? { get }
    var clips: [Clip] { get }
}
