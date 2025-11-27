import { NativeModule, requireNativeModule } from "expo-modules-core";
import type {
  FetchAssetsOptions,
  PHAuthorizationStatus,
  PHAccessLevel,
  PHAsset,
  PickAssetsOptions,
  RequestImageOptions,
  RequestVideoOptions,
} from "./ExpoPhotos.types";

export declare class ExpoPhotosModule extends NativeModule {
  fetchAssets(options: FetchAssetsOptions): Promise<PHAsset[]>;
  requestImage(options: RequestImageOptions): Promise<void>;
  requestVideo(options: RequestVideoOptions): Promise<void>;
  pickAssets(options: PickAssetsOptions): Promise<PHAsset[]>;
  requestAuthorization(accessLevel: PHAccessLevel): Promise<PHAuthorizationStatus>;
  presentLimitedLibraryPicker(): Promise<void>;
}

export default requireNativeModule<ExpoPhotosModule>("ExpoPhotos");
