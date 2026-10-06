import { NativeModule, requireNativeModule } from "expo-modules-core";
import type {
  FetchAssetsOptions,
  PHAuthorizationStatus,
  PHAccessLevel,
  PHAsset,
  PickAssetsOptions,
  RequestImageOptions,
  RequestVideoOptions,
  RequestImageResult,
} from "./ExpoPhotos.types";

export declare class ExpoPhotosModule extends NativeModule {
  fetchAssets(options: FetchAssetsOptions): Promise<PHAsset[]>;
  requestImage(options: RequestImageOptions): Promise<RequestImageResult>;
  requestVideo(options: RequestVideoOptions): Promise<void>;
  pickAssets(options: PickAssetsOptions): Promise<PHAsset[]>;
  authorizationStatus(accessLevel: PHAccessLevel): Promise<PHAuthorizationStatus>;
  requestAuthorization(accessLevel: PHAccessLevel): Promise<PHAuthorizationStatus>;
  /** Resolves with newly selected local identifiers once the picker closes. */
  presentLimitedLibraryPicker(): Promise<string[]>;
}

export default requireNativeModule<ExpoPhotosModule>("ExpoPhotos");
