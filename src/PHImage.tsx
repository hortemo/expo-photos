import { requireNativeViewManager } from "expo-modules-core";
import { ViewProps } from "react-native";
import {
  PHImageContentMode,
  PHImageRequestOptionsDeliveryMode,
  PHImageRequestOptionsResizeMode,
} from "./ExpoPhotos.types";

export interface PHImageLoadEvent {
  size: { width: number; height: number };
  scale: number;
}

export interface PHImageErrorEvent {
  message: string;
}

export interface PHImageProps extends ViewProps {
  localIdentifier: string;
  isNetworkAccessAllowed?: boolean;
  deliveryMode?: PHImageRequestOptionsDeliveryMode;
  resizeMode?: PHImageRequestOptionsResizeMode;
  contentMode?: PHImageContentMode;
  onLoad?: (event: { nativeEvent: PHImageLoadEvent }) => void;
  onError?: (event: { nativeEvent: PHImageErrorEvent }) => void;
}

const NativePHImageView = requireNativeViewManager("ExpoPhotos", "PHImageView");

export function PHImage(props: PHImageProps) {
  return <NativePHImageView {...props} />;
}
