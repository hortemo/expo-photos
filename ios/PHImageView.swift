import ExpoModulesCore
import Photos
import UIKit

public final class PHImageView: ExpoView {
  let onLoad = EventDispatcher()
  let onError = EventDispatcher()

  private var currentRequestId: PHImageRequestID?
  private var imageView: UIImageView

  var localIdentifier: String? {
    didSet {
      if localIdentifier != oldValue {
        loadImage()
      }
    }
  }

  var isNetworkAccessAllowed: Bool = true {
    didSet {
      if isNetworkAccessAllowed != oldValue {
        loadImage()
      }
    }
  }

  var deliveryMode: PHImageRequestOptionsDeliveryMode = .opportunistic {
    didSet {
      if deliveryMode != oldValue {
        loadImage()
      }
    }
  }

  var resizeMode: PHImageRequestOptionsResizeMode = .none {
    didSet {
      if resizeMode != oldValue {
        loadImage()
      }
    }
  }

  var targetSize: CGSize? {
    didSet {
      if targetSize != oldValue {
        loadImage()
      }
    }
  }

  var requestContentMode: PHImageContentMode = .aspectFill {
    didSet {
      if requestContentMode != oldValue {
        loadImage()
      }
    }
  }

  var viewContentMode: UIView.ContentMode = .scaleAspectFill {
    didSet {
      if viewContentMode != oldValue {
        imageView.contentMode = viewContentMode
      }
    }
  }

  public required init(appContext: AppContext? = nil) {
    imageView = UIImageView()
    super.init(appContext: appContext)
    imageView.clipsToBounds = true
    imageView.contentMode = viewContentMode
    addSubview(imageView)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    imageView.frame = bounds
    loadImage()
  }

  public override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    if newWindow == nil {
      cleanup()
    }
  }

  private func loadImage() {
    cleanup()

    guard let localIdentifier = localIdentifier else { return }
    guard bounds.width > 0 && bounds.height > 0 else { return }

    guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject else {
      onError(["message": "Asset not found for identifier: \(localIdentifier)"])
      return
    }

    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = isNetworkAccessAllowed
    options.deliveryMode = deliveryMode
    options.resizeMode = resizeMode

    let scale = window?.screen.scale ?? UIScreen.main.scale
    let boundsSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)

    currentRequestId = PHImageManager.default().requestImage(
      for: asset,
      targetSize: targetSize ?? boundsSize,
      contentMode: requestContentMode,
      options: options
    ) { [weak self] image, info in
      guard let self = self else { return }

      DispatchQueue.main.async {
        let isCancelled = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue ?? false
        if isCancelled { return }

        if let error = info?[PHImageErrorKey] as? Error {
          self.onError(["message": error.localizedDescription])
          return
        }

        guard let image = image else {
          self.onError(["message": "Failed to load image"])
          return
        }

        self.imageView.image = image

        let isDegraded = (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false
        if !isDegraded {
          self.onLoad([
            "size": [
              "width": image.size.width,
              "height": image.size.height,
            ],
            "scale": image.scale,
          ])
        }
      }
    }
  }

  private func cleanup() {
    if let requestId = currentRequestId {
      PHImageManager.default().cancelImageRequest(requestId)
      currentRequestId = nil
    }
  }
}
