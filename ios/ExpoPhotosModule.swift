import ExpoModulesCore
import Foundation
import Photos
import PhotosUI
import SDWebImageWebPCoder
import UIKit

struct FetchAssetsOptions: Record {
  @Field var predicate: NSPredicate?
  @Field var fetchLimit: Int?
  @Field var sortDescriptors: [NSSortDescriptor]?
}

struct RequestImageOptions: Record {
  @Field var localIdentifier: String?
  @Field var targetSize: CGSize?
  @Field var contentMode: PHImageContentMode?
  @Field var isNetworkAccessAllowed: Bool?
  @Field var deliveryMode: PHImageRequestOptionsDeliveryMode?
  @Field var resizeMode: PHImageRequestOptionsResizeMode?
  @Field var outputURL: URL?
  @Field var encodeCompressionQuality: Double?
  @Field var encodeMaxFileSize: Int?
  @Field var timeout: TimeInterval?
}

protocol AVAssetExportSessionOptions {
  var outputURL: URL? { get }
  var outputFileType: AVFileType? { get }
  var fileLengthLimit: Int64? { get }
  var timeRange: CMTimeRange? { get }
}

struct RequestVideoOptions: Record, AVAssetExportSessionOptions {
  @Field var localIdentifier: String?
  @Field var isNetworkAccessAllowed: Bool?
  @Field var deliveryMode: PHVideoRequestOptionsDeliveryMode?
  @Field var exportPreset: String?
  @Field var outputURL: URL?
  @Field var outputFileType: AVFileType?
  @Field var fileLengthLimit: Int64?
  @Field var timeRange: CMTimeRange?
  @Field var timeout: TimeInterval?
}

struct PickAssetsOptions: Record {
  @Field var filter: PHPickerFilter?
  @Field var selectionLimit: Int?
}

enum ExpoPhotosError: Error {
  case mandatoryFieldMissing
  case couldNotFindAsset
  case couldNotEncodeImage
  case couldNotCreateExportSession
  case noViewController
  case unknown
}

public class ExpoPhotos: Module {
  private var pickAssetsContinuations = [
    ObjectIdentifier: CheckedContinuation<[[String: Any]], Error>
  ]()

  public func definition() -> ModuleDefinition {
    Name("ExpoPhotos")

    AsyncFunction("fetchAssets") { (options: FetchAssetsOptions) -> [[String: Any]] in
      let fetchOptions = PHFetchOptions()

      if let predicate = options.predicate {
        fetchOptions.predicate = predicate
      }

      if let fetchLimit = options.fetchLimit {
        fetchOptions.fetchLimit = fetchLimit
      }

      if let sortDescriptors = options.sortDescriptors {
        fetchOptions.sortDescriptors = sortDescriptors
      }

      var assets: [[String: Any]] = []
      PHAsset.fetchAssets(with: fetchOptions).enumerateObjects { asset, _, _ in
        assets.append(asset.toJS())
      }
      return assets
    }

    AsyncFunction("requestAuthorization") { (accessLevel: PHAccessLevel) async throws -> Int in
      let status = await PHPhotoLibrary.requestAuthorization(for: accessLevel)
      return status.rawValue
    }

    AsyncFunction("requestImage") { (options: RequestImageOptions) async throws -> Void in
      guard
        let localIdentifier = options.localIdentifier,
        let targetSize = options.targetSize,
        let contentMode = options.contentMode,
        let outputURL = options.outputURL
      else {
        throw ExpoPhotosError.mandatoryFieldMissing
      }

      guard let asset = PHAsset.fetchAsset(withLocalIdentifier: localIdentifier) else {
        throw ExpoPhotosError.couldNotFindAsset
      }

      let imageRequestOptions = PHImageRequestOptions()

      if let isNetworkAccessAllowed = options.isNetworkAccessAllowed {
        imageRequestOptions.isNetworkAccessAllowed = isNetworkAccessAllowed
      }

      if let deliveryMode = options.deliveryMode {
        imageRequestOptions.deliveryMode = deliveryMode
      }

      if let resizeMode = options.resizeMode {
        imageRequestOptions.resizeMode = resizeMode
      }

      let deadline = options.timeout.map { DispatchTime.now() + $0 }

      let image = try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<UIImage, Error>) in
        let requestId = PHImageManager.default().requestImage(
          for: asset,
          targetSize: targetSize,
          contentMode: contentMode,
          options: imageRequestOptions
        ) { image, info in
          guard let image = image else {
            let error = info?[PHImageErrorKey] as? Error ?? ExpoPhotosError.unknown
            continuation.resume(throwing: error)
            return
          }
          continuation.resume(returning: image)
        }

        if let deadline = deadline {
          DispatchQueue.global().asyncAfter(deadline: deadline) {
            PHImageManager.default().cancelImageRequest(requestId)
          }
        }
      }

      var imageCoderOptions: [SDImageCoderOption: Any] = [:]

      if let encodeCompressionQuality = options.encodeCompressionQuality {
        imageCoderOptions[.encodeCompressionQuality] = encodeCompressionQuality
      }

      if let encodeMaxFileSize = options.encodeMaxFileSize {
        imageCoderOptions[.encodeMaxFileSize] = encodeMaxFileSize
      }

      guard
        let data = SDImageWebPCoder.shared.encodedData(
          with: image, format: .webP, options: imageCoderOptions)
      else {
        throw ExpoPhotosError.couldNotEncodeImage
      }

      try data.write(to: outputURL)
    }

    AsyncFunction("requestVideo") { (options: RequestVideoOptions) async throws -> Void in
      guard
        let localIdentifier = options.localIdentifier,
        let exportPreset = options.exportPreset,
        options.outputURL != nil
      else {
        throw ExpoPhotosError.mandatoryFieldMissing
      }

      guard let asset = PHAsset.fetchAsset(withLocalIdentifier: localIdentifier) else {
        throw ExpoPhotosError.couldNotFindAsset
      }

      let videoRequestOptions = PHVideoRequestOptions()

      if let isNetworkAccessAllowed = options.isNetworkAccessAllowed {
        videoRequestOptions.isNetworkAccessAllowed = isNetworkAccessAllowed
      }

      if let deliveryMode = options.deliveryMode {
        videoRequestOptions.deliveryMode = deliveryMode
      }

      let deadline = options.timeout.map { DispatchTime.now() + $0 }

      let exportSession = try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<AVAssetExportSession, Error>) in
        let requestId = PHImageManager.default().requestExportSession(
          forVideo: asset,
          options: videoRequestOptions,
          exportPreset: exportPreset
        ) { exportSession, info in
          guard let exportSession = exportSession else {
            let error = info?[PHImageErrorKey] as? Error ?? ExpoPhotosError.unknown
            continuation.resume(throwing: error)
            return
          }
          continuation.resume(returning: exportSession)
        }

        if let deadline = deadline {
          DispatchQueue.global().asyncAfter(deadline: deadline) {
            PHImageManager.default().cancelImageRequest(requestId)
          }
        }
      }

      if let outputURL = options.outputURL {
        exportSession.outputURL = outputURL
      }

      if let outputFileType = options.outputFileType {
        exportSession.outputFileType = outputFileType
      }

      if let fileLengthLimit = options.fileLengthLimit {
        exportSession.fileLengthLimit = fileLengthLimit
      }

      if let timeRange = options.timeRange {
        exportSession.timeRange = timeRange
      }

      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<Void, Error>) in
        exportSession.exportAsynchronously {
          switch exportSession.status {
          case .completed:
            continuation.resume()
          default:
            let error = exportSession.error ?? ExpoPhotosError.unknown
            continuation.resume(throwing: error)
          }
        }

        if let deadline = deadline {
          DispatchQueue.global().asyncAfter(deadline: deadline) {
            exportSession.cancelExport()
          }
        }
      }
    }

    AsyncFunction("presentLimitedLibraryPicker") { () async throws -> Void in
      guard let viewController = self.appContext?.utilities?.currentViewController() else {
        throw ExpoPhotosError.noViewController
      }

      await PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: viewController)
    }

    AsyncFunction("pickAssets") { (options: PickAssetsOptions) async throws -> [[String: Any]] in
      guard let viewController = self.appContext?.utilities?.currentViewController() else {
        throw ExpoPhotosError.noViewController
      }

      let picker: PHPickerViewController = await MainActor.run {
        var config = PHPickerConfiguration(photoLibrary: .shared())

        if let selectionLimit = options.selectionLimit {
          config.selectionLimit = selectionLimit
        }

        if let filter = options.filter {
          config.filter = filter
        }

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self

        return picker
      }

      return try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<[[String: Any]], Error>) in
        self.pickAssetsContinuations[picker.id] = continuation

        Task {
          await viewController.present(picker, animated: true, completion: nil)
        }
      }
    }
  }
}

extension ExpoPhotos: PHPickerViewControllerDelegate {
  public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true, completion: nil)

    guard let continuation = self.pickAssetsContinuations[picker.id] else {
      return
    }

    self.pickAssetsContinuations.removeValue(forKey: picker.id)

    let assetIdentifiers = results.compactMap { $0.assetIdentifier }
    var assets: [[String: Any]] = []
    PHAsset.fetchAssets(withLocalIdentifiers: assetIdentifiers, options: nil).enumerateObjects {
      asset, _, _ in
      assets.append(asset.toJS())
    }

    continuation.resume(returning: assets)
  }
}

extension PHPickerViewController {
  var id: ObjectIdentifier {
    return ObjectIdentifier(self)
  }
}

extension TimeInterval: @retroactive Convertible {
  public static func convert(from value: Any?, appContext: AppContext) throws -> Self {
    guard let milliseconds = value as? Int else {
      throw Conversions.ConvertingException<Self>(value)
    }
    return Double(milliseconds) / 1000
  }

  func toJS() -> Int {
    return Int(self * 1000)
  }
}

extension CMTime {
  func toJS() -> Int {
    return Int(self.seconds * 1000)
  }
}

extension PHAsset {
  public static func fetchAsset(withLocalIdentifier identifier: String) -> PHAsset? {
    return PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject
  }

  func toJS() -> [String: Any] {
    return [
      "localIdentifier": localIdentifier,
      "creationDate": creationDate?.timeIntervalSince1970.toJS() ?? NSNull(),
      "mediaType": mediaType.rawValue,
      "mediaSubtypes": mediaSubtypes.rawValue,
      "duration": duration.toJS(),
    ]
  }
}

extension NSSortDescriptor: @retroactive Convertible {
  public static func convert(from value: Any?, appContext: AppContext) throws -> Self {
    guard
      let dict = value as? [String: Any],
      let key = dict["key"] as? String,
      let ascending = dict["ascending"] as? Bool
    else {
      throw Conversions.ConvertingException<NSSortDescriptor>(value)
    }
    return Self(key: key, ascending: ascending)
  }
}

extension NSPredicate: @retroactive Convertible {
  public static func convert(from value: Any?, appContext: AppContext) throws -> Self {
    guard
      let rawValue = value as? String,
      let predicate = NSPredicate(format: rawValue) as? Self
    else {
      throw Conversions.ConvertingException<Self>(value)
    }
    return predicate
  }
}

extension CMTimeRange: @retroactive Convertible {
  public static func convert(from value: Any?, appContext: AppContext) throws -> Self {
    guard let dict = value as? [String: Any],
      let startMs = dict["start"] as? Int,
      let durationMs = dict["duration"] as? Int
    else {
      throw Conversions.ConvertingException<CMTimeRange>(value)
    }

    return Self(
      start: CMTimeMakeWithSeconds(Double(startMs) / 1000, preferredTimescale: 600),
      duration: CMTimeMakeWithSeconds(Double(durationMs) / 1000, preferredTimescale: 600)
    )
  }
}

extension Convertible where Self: RawRepresentable, Self.RawValue == Int {
  public static func convert(from value: Any?, appContext: AppContext) throws -> Self {
    guard
      let rawValue = value as? Int,
      let enumValue = Self(rawValue: rawValue)
    else {
      throw Conversions.ConvertingException<Self>(value)
    }
    return enumValue
  }
}

extension Convertible where Self: RawRepresentable, Self.RawValue == String {
  public static func convert(from value: Any?, appContext: AppContext) throws -> Self {
    guard
      let rawValue = value as? String,
      let enumValue = Self(rawValue: rawValue)
    else {
      throw Conversions.ConvertingException<Self>(value)
    }
    return enumValue
  }
}

extension PHImageRequestOptionsDeliveryMode: @retroactive Convertible {}
extension PHImageRequestOptionsResizeMode: @retroactive Convertible {}
extension PHImageContentMode: @retroactive Convertible {}
extension PHVideoRequestOptionsDeliveryMode: @retroactive Convertible {}
extension AVFileType: @retroactive Convertible {}
extension PHAccessLevel: @retroactive Convertible {}

extension PHPickerFilter: @retroactive Convertible {
  public static func convert(from value: Any?, appContext: AppContext) throws -> Self {
    guard let rawValue = value as? String else {
      throw Conversions.ConvertingException<Self>(value)
    }
    switch rawValue {
    case "images":
      return .images
    case "videos":
      return .videos
    case "any":
      return .any(of: [.images, .videos])
    default:
      throw Conversions.ConvertingException<Self>(value)
    }
  }
}
