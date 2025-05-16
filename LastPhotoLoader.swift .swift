import Photos
import UIKit

struct LastPhotoLoader {
    static func fetch(completion: @escaping (UIImage?) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                completion(nil); return
            }
            
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.fetchLimit = 1
            
            if let asset = PHAsset.fetchAssets(with: .image, options: options).firstObject {
                let imgMgr = PHImageManager.default()
                let target = CGSize(width: 100, height: 100)
                imgMgr.requestImage(for: asset,
                                    targetSize: target,
                                    contentMode: .aspectFill,
                                    options: nil) { image, _ in
                    completion(image)
                }
            } else {
                completion(nil)
            }
        }
    }
}
