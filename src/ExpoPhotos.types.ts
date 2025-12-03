export interface PHAsset {
  localIdentifier: string;
  creationDate: number;
  mediaType: PHAssetMediaType;
  mediaSubtypes: PHAssetMediaSubtype;
  duration: number;
}

export enum PHAuthorizationStatus {
  notDetermined = 0,
  restricted = 1,
  denied = 2,
  authorized = 3,
  limited = 4,
}

export enum PHAccessLevel {
  addOnly = 1,
  readWrite = 2,
}

export enum PHAssetMediaType {
  Unknown = 0,
  Image = 1,
  Video = 2,
  Audio = 3,
}

export enum PHAssetMediaSubtype {
  None = 0,
  PhotoPanorama = 1 << 0,
  PhotoHDR = 1 << 1,
  PhotoScreenshot = 1 << 2,
  PhotoLive = 1 << 3,
  PhotoDepthEffect = 1 << 4,
  VideoStreamed = 1 << 16,
  VideoHighFrameRate = 1 << 17,
  VideoTimelapse = 1 << 18,
  VideoCinematic = 1 << 19,
}

export interface NSSortDescriptor {
  key: string;
  ascending: boolean;
}

export interface PHFetchOptions {
  predicate?: string;
  fetchLimit?: number;
  sortDescriptors?: NSSortDescriptor[];
}

export type FetchAssetsOptions = PHFetchOptions;

export interface CGSize {
  width: number;
  height: number;
}

export type PHImageManagerMaximumSize = "PHImageManagerMaximumSize";

export type RequestImageTargetSize = CGSize | PHImageManagerMaximumSize;

export enum PHImageRequestOptionsResizeMode {
  None = 0,
  Fast = 1,
  Exact = 2,
}

export enum PHImageRequestOptionsDeliveryMode {
  Opportunistic = 0,
  HighQualityFormat = 1,
  FastFormat = 2,
}

export enum PHImageContentMode {
  aspectFit = 0,
  aspectFill = 1,
}

export interface PHImageRequestOptions {
  isNetworkAccessAllowed?: boolean;
  resizeMode?: PHImageRequestOptionsResizeMode;
  deliveryMode?: PHImageRequestOptionsDeliveryMode;
}

export interface SDImageCoderOptions {
  encodeCompressionQuality?: number;
  encodeMaxFileSize?: number;
}

export enum PHVideoRequestOptionsDeliveryMode {
  Automatic = 0,
  HighQualityFormat = 1,
  MediumQualityFormat = 2,
  FastFormat = 3,
}

export interface PHVideoRequestOptions {
  isNetworkAccessAllowed?: boolean;
  deliveryMode?: PHVideoRequestOptionsDeliveryMode;
}

export interface CMTimeRange {
  start: number;
  duration: number;
}

export enum AVFileType {
  ac3 = "public.ac3-audio",
  aifc = "public.aifc-audio",
  aiff = "public.aiff-audio",
  AHAP = "com.apple.itt",
  amr = "org.3gpp.adaptive-multi-rate-audio",
  appleiTT = "com.apple.itt",
  au = "public.au-audio",
  avci = "public.avci",
  caf = "com.apple.coreaudio-format",
  dng = "com.adobe.raw-image",
  eac3 = "public.eac3-audio",
  heic = "public.heic",
  heif = "public.heif",
  jpg = "public.jpeg",
  m4a = "com.apple.m4a-audio",
  m4v = "com.apple.m4v-video",
  mobile3GPP = "public.3gpp",
  mobile3GPP2 = "public.3gpp2",
  mov = "com.apple.quicktime-movie",
  mp3 = "public.mp3",
  mp4 = "public.mpeg-4",
  SCC = "com.scenarist.cc",
  tif = "public.tiff",
  wav = "com.microsoft.waveform-audio",
}

export enum AVAssetExportPreset {
  LowQuality = "AVAssetExportPresetLowQuality",
  MediumQuality = "AVAssetExportPresetMediumQuality",
  HighestQuality = "AVAssetExportPresetHighestQuality",
  HEVCHighestQuality = "AVAssetExportPresetHEVCHighestQuality",
  HEVCHighestQualityWithAlpha = "AVAssetExportPresetHEVCHighestQualityWithAlpha",
  AVC640x480 = "AVAssetExportPreset640x480",
  AVC960x540 = "AVAssetExportPreset960x540",
  AVC1280x720 = "AVAssetExportPreset1280x720",
  AVC1920x1080 = "AVAssetExportPreset1920x1080",
  AVC3840x2160 = "AVAssetExportPreset3840x2160",
  HEVC1920x1080 = "AVAssetExportPresetHEVC1920x1080",
  HEVC3840x2160 = "AVAssetExportPresetHEVC3840x2160",
  HEVC1920x1080WithAlpha = "AVAssetExportPresetHEVC1920x1080WithAlpha",
  HEVC3840x2160WithAlpha = "AVAssetExportPresetHEVC3840x2160WithAlpha",
  HEVC7680x4320 = "AVAssetExportPresetHEVC7680x4320",
  MVHEVC960x960 = "AVAssetExportPresetMVHEVC960x960",
  MVHEVC1440x1440 = "AVAssetExportPresetMVHEVC1440x1440",
  AppleM4V480pSD = "AVAssetExportPresetAppleM4V480pSD",
  AppleM4V720pHD = "AVAssetExportPresetAppleM4V720pHD",
  AppleM4V1080pHD = "AVAssetExportPresetAppleM4V1080pHD",
  AppleM4ViPod = "AVAssetExportPresetAppleM4ViPod",
  AppleM4VAppleTV = "AVAssetExportPresetAppleM4VAppleTV",
  AppleM4VCellular = "AVAssetExportPresetAppleM4VCellular",
  AppleM4VWiFi = "AVAssetExportPresetAppleM4VWiFi",
  AppleProRes422LPCM = "AVAssetExportPresetAppleProRes422LPCM",
  AppleProRes4444LPCM = "AVAssetExportPresetAppleProRes4444LPCM",
  Passthrough = "AVAssetExportPresetPassthrough",
  AppleM4A = "AVAssetExportPresetAppleM4A",
}

export interface AVAssetExportSessionOptions {
  outputURL: string;
  outputFileType?: AVFileType;
  fileLengthLimit?: number;
  timeRange?: CMTimeRange;
}

export interface RequestImageOptions
  extends PHImageRequestOptions,
    SDImageCoderOptions {
  localIdentifier: string;
  targetSize: RequestImageTargetSize;
  contentMode: PHImageContentMode;
  outputURL?: string;
  timeout?: number;
}

export interface RequestImageResult {
  size: CGSize;
  scale: number;
  imageOrientation: number;
}

export interface RequestVideoOptions
  extends PHVideoRequestOptions,
    AVAssetExportSessionOptions {
  localIdentifier: string;
  exportPreset: AVAssetExportPreset;
  timeout?: number;
}

export enum PHPickerFilter {
  images = "images",
  videos = "videos",
  any = "any",
}

export interface PickAssetsOptions {
  filter?: PHPickerFilter;
  selectionLimit?: number;
}
