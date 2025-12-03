#if canImport(React)
import Foundation
import Photos
import React
import UIKit

@objc(ExpoPhotosImageLoader)
class ExpoPhotosImageLoader: NSObject, RCTBridgeModule, RCTImageURLLoader {
  static func moduleName() -> String! {
    return "ExpoPhotosImageLoader"
  }

  static func requiresMainQueueSetup() -> Bool {
    return false
  }

  // MARK: - Helper Functions

  private static func queryItems(from url: URL) -> [String: String] {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
      return [:]
    }

    var result: [String: String] = [:]
    for item in queryItems {
      if let value = item.value {
        result[item.name] = value
      }
    }
    return result
  }

  private static let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    return formatter
  }()

  private static func number(from string: String?) -> NSNumber? {
    guard let string = string else {
      return nil
    }
    return numberFormatter.number(from: string)
  }

  private static func bool(from string: String?) -> Bool {
    guard let string = string else {
      return false
    }

    let lower = string.lowercased()
    return lower == "1" || lower == "true" || lower == "yes"
  }

  // MARK: - RCTImageURLLoader

  func canLoadImageURL(_ requestURL: URL) -> Bool {
    return requestURL.scheme?.caseInsensitiveCompare("expo-photos") == .orderedSame
  }

  func loaderPriority() -> Float {
    return 1.0
  }

  func loadImage(
    for imageURL: URL,
    size: CGSize,
    scale: CGFloat,
    resizeMode: RCTResizeMode,
    progressHandler: RCTImageLoaderProgressBlock!,
    partialLoadHandler: RCTImageLoaderPartialLoadBlock!,
    completionHandler: @escaping RCTImageLoaderCompletionBlock
  ) -> RCTImageLoaderCancellationBlock! {

    guard imageURL.scheme?.caseInsensitiveCompare("expo-photos") == .orderedSame else {
      completionHandler(RCTErrorWithMessage("Unsupported image URL scheme for ExpoPhotos"), nil)
      return {}
    }

    let queryParams = Self.queryItems(from: imageURL)

    // Using PhotoKit for iOS 8+
    guard let assetID = queryParams["localIdentifier"], !assetID.isEmpty else {
      completionHandler(RCTErrorWithMessage("Missing localIdentifier query parameter"), nil)
      return {}
    }

    let results = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
    guard results.count > 0 else {
      let errorText = "Failed to fetch PHAsset with local identifier \(assetID) with no error message."
      completionHandler(RCTErrorWithMessage(errorText), nil)
      return {}
    }

    let asset = results.firstObject!
    let imageOptions = PHImageRequestOptions()

    var targetSize = size.applying(CGAffineTransform(scaleX: scale, y: scale))

    if let targetSizeString = queryParams["targetSize"], !targetSizeString.isEmpty {
      let components = targetSizeString.lowercased().components(separatedBy: "x")
      guard components.count == 2,
            let width = Self.number(from: components[0]),
            let height = Self.number(from: components[1]) else {
        completionHandler(RCTErrorWithMessage("Invalid targetSize format. Expected WIDTHxHEIGHT."), nil)
        return {}
      }
      targetSize = CGSize(width: width.doubleValue, height: height.doubleValue)
    }

    if let deliveryModeString = queryParams["deliveryMode"], !deliveryModeString.isEmpty {
      guard let deliveryModeNumber = Self.number(from: deliveryModeString),
            let deliveryMode = PHImageRequestOptionsDeliveryMode(rawValue: deliveryModeNumber.intValue) else {
        completionHandler(RCTErrorWithMessage("Invalid deliveryMode value."), nil)
        return {}
      }
      imageOptions.deliveryMode = deliveryMode
    }

    if let resizeModeString = queryParams["resizeMode"], !resizeModeString.isEmpty {
      guard let resizeModeNumber = Self.number(from: resizeModeString),
            let resizeMode = PHImageRequestOptionsResizeMode(rawValue: resizeModeNumber.intValue) else {
        completionHandler(RCTErrorWithMessage("Invalid resizeMode value."), nil)
        return {}
      }
      imageOptions.resizeMode = resizeMode
    }

    if let isNetworkAccessAllowedString = queryParams["isNetworkAccessAllowed"], !isNetworkAccessAllowedString.isEmpty {
      imageOptions.isNetworkAccessAllowed = Self.bool(from: isNetworkAccessAllowedString)
    }

    var contentMode: PHImageContentMode = .default
    if let contentModeString = queryParams["contentMode"], !contentModeString.isEmpty {
      guard let contentModeNumber = Self.number(from: contentModeString),
            let _contentMode = PHImageContentMode(rawValue: contentModeNumber.intValue) else {
        completionHandler(RCTErrorWithMessage("Invalid contentMode value."), nil)
        return {}
      }
      contentMode = _contentMode
    }

    if let progressHandler = progressHandler {
      imageOptions.progressHandler = { progress, error, stop, info in
        let multiplier: Int64 = 1_000_000
        progressHandler(Int64(progress * Double(multiplier)), multiplier)
      }
    }

    let requestID = PHImageManager.default().requestImage(
      for: asset,
      targetSize: targetSize,
      contentMode: contentMode,
      options: imageOptions
    ) { result, info in
      guard let info = info else {
        return
      }

      let isCancelled = (info[PHImageCancelledKey] as? NSNumber)?.boolValue ?? false
      let isDegraded = (info[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false

      if isCancelled {
        return
      }

      if let result = result {
        if isDegraded {
          partialLoadHandler?(result)
        } else {
          completionHandler(nil, result)
        }
      } else if let error = info[PHImageErrorKey] as? Error {
        completionHandler(error, nil)
      }
    }

    return {
      PHImageManager.default().cancelImageRequest(requestID)
    }
  }
}

#endif

