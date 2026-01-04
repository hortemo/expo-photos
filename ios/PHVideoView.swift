import AVFoundation
import ExpoModulesCore
import Photos
import UIKit

public final class PHVideoView: ExpoView {
  let onLoad = EventDispatcher()
  let onError = EventDispatcher()

  private var playerLayer: AVPlayerLayer?
  private var playerLooper: AVPlayerLooper?
  private var queuePlayer: AVQueuePlayer?
  private var templateItem: AVPlayerItem?
  private var currentRequestId: PHImageRequestID?
  private var statusObserver: NSKeyValueObservation?
  private var didSendLoadEvent = false

  var localIdentifier: String? {
    didSet {
      if localIdentifier != oldValue {
        loadVideo()
      }
    }
  }

  var isNetworkAccessAllowed: Bool = true {
    didSet {
      if isNetworkAccessAllowed != oldValue {
        loadVideo()
      }
    }
  }

  var deliveryMode: PHVideoRequestOptionsDeliveryMode = .automatic {
    didSet {
      if deliveryMode != oldValue {
        loadVideo()
      }
    }
  }

  public required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    setupPlayerLayer()
  }

  private func setupPlayerLayer() {
    let layer = AVPlayerLayer()
    layer.videoGravity = .resizeAspect
    self.layer.addSublayer(layer)
    playerLayer = layer
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    playerLayer?.frame = bounds
  }

  public override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    if newWindow == nil {
      cleanup()
    }
  }

  private func loadVideo() {
    cleanup()

    guard let localIdentifier = localIdentifier else { return }

    guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject else {
      onError(["message": "Asset not found for identifier: \(localIdentifier)"])
      return
    }

    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = isNetworkAccessAllowed
    options.deliveryMode = deliveryMode

    currentRequestId = PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { [weak self] playerItem, info in
      guard let self = self else { return }

      DispatchQueue.main.async {
        if let error = info?[PHImageErrorKey] as? Error {
          self.onError(["message": error.localizedDescription])
          return
        }

        guard let playerItem = playerItem else {
          self.onError(["message": "Failed to load video"])
          return
        }

        self.setupPlayer(with: playerItem)
      }
    }
  }

  private func setupPlayer(with playerItem: AVPlayerItem) {
    didSendLoadEvent = false
    
    // AVPlayerLooper requires an empty AVQueuePlayer - it manages the items
    let queuePlayer = AVQueuePlayer()
    queuePlayer.isMuted = false
    
    // Keep strong reference to template item
    self.templateItem = playerItem
    
    // Create looper - it will insert copies of the template item
    let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
    
    playerLayer?.player = queuePlayer
    self.queuePlayer = queuePlayer
    self.playerLooper = looper

    // Observe the queue player's current item status
    statusObserver = queuePlayer.observe(\.status, options: [.initial, .new]) { [weak self] player, _ in
      guard let self = self else { return }
      
      DispatchQueue.main.async {
        switch player.status {
        case .readyToPlay:
          if !self.didSendLoadEvent {
            self.didSendLoadEvent = true
            let duration = playerItem.asset.duration.seconds.isFinite ? playerItem.asset.duration.seconds * 1000 : 0
            let tracks = playerItem.asset.tracks(withMediaType: .video)
            let size = tracks.first?.naturalSize ?? .zero
            self.onLoad([
              "duration": duration,
              "naturalSize": [
                "width": size.width,
                "height": size.height
              ]
            ])
          }
          player.play()
        case .failed:
          let message = player.error?.localizedDescription ?? "Unknown error"
          self.onError(["message": message])
        default:
          break
        }
      }
    }
  }

  private func cleanup() {
    statusObserver?.invalidate()
    statusObserver = nil
    
    if let requestId = currentRequestId {
      PHImageManager.default().cancelImageRequest(requestId)
      currentRequestId = nil
    }
    
    queuePlayer?.pause()
    queuePlayer?.removeAllItems()
    playerLooper = nil
    queuePlayer = nil
    templateItem = nil
    playerLayer?.player = nil
    didSendLoadEvent = false
  }
}
