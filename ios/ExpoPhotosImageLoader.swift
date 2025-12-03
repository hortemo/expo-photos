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

    guard let localIdentifier = queryParams["localIdentifier"], !localIdentifier.isEmpty else {
      completionHandler(RCTErrorWithMessage("Missing localIdentifier query parameter"), nil)
      return {}
    }

    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
    guard let asset = assets.firstObject else {
      completionHandler(RCTErrorWithMessage("Failed to fetch PHAsset with local identifier \(localIdentifier)"), nil)
      return {}
    }

    let imageOptions = PHImageRequestOptions()

    var targetSize = size.applying(CGAffineTransform(scaleX: scale, y: scale))

    if let targetSizeString = queryParams["targetSize"] {
      let components = targetSizeString.lowercased().components(separatedBy: "x")
      guard components.count == 2,
            let width = Double(components[0]),
            let height = Double(components[1]) else {
        completionHandler(RCTErrorWithMessage("Invalid targetSize format. Expected WIDTHxHEIGHT."), nil)
        return {}
      }
      targetSize = CGSize(width: width, height: height)
    }

    if let deliveryModeString = queryParams["deliveryMode"] {
      guard let deliveryMode = PHImageRequestOptionsDeliveryMode.from(queryParam: deliveryModeString) else {
        completionHandler(RCTErrorWithMessage("Invalid deliveryMode value."), nil)
        return {}
      }
      imageOptions.deliveryMode = deliveryMode
    }

    if let resizeModeString = queryParams["resizeMode"] {
      guard let resizeMode = PHImageRequestOptionsResizeMode.from(queryParam: resizeModeString) else {
        completionHandler(RCTErrorWithMessage("Invalid resizeMode value."), nil)
        return {}
      }
      imageOptions.resizeMode = resizeMode
    }

    if let isNetworkAccessAllowedString = queryParams["isNetworkAccessAllowed"] {
      imageOptions.isNetworkAccessAllowed = Bool.from(queryParam: isNetworkAccessAllowedString)
    }

    var contentMode: PHImageContentMode = .default
    if let contentModeString = queryParams["contentMode"] {
      guard let _contentMode = PHImageContentMode.from(queryParam: contentModeString) else {
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

// MARK: - RawRepresentable Extension

extension RawRepresentable where RawValue == Int {
  static func from(queryParam string: String?) -> Self? {
    guard let string = string, !string.isEmpty else {
      return nil
    }
    guard let intValue = Int(string) else {
      return nil
    }
    return Self(rawValue: intValue)
  }
}

// MARK: - Bool Extension

extension Bool {
  static func from(queryParam string: String?) -> Bool {
    guard let string = string, !string.isEmpty else {
      return false
    }
    return string.lowercased() == "true"
  }
}

#endif

