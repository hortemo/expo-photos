import { requireNativeViewManager } from "expo-modules-core";
import { ViewProps } from "react-native";
import {
  PHImageContentMode,
  PHImageRequestOptions,
  RequestImageTargetSize,
  UIViewContentMode,
} from "./ExpoPhotos.types";

export interface PHImageLoadEvent {
  size: { width: number; height: number };
  scale: number;
}

export interface PHImageErrorEvent {
  message: string;
}

export interface PHImageViewRequestOptions extends PHImageRequestOptions {
  contentMode?: PHImageContentMode;
  targetSize?: RequestImageTargetSize;
}

export interface PHImageViewProps extends ViewProps {
  localIdentifier: string;
  contentMode?: UIViewContentMode;
  requestOptions?: PHImageViewRequestOptions;
  onLoad?: (event: { nativeEvent: PHImageLoadEvent }) => void;
  onError?: (event: { nativeEvent: PHImageErrorEvent }) => void;
}

const NativePHImageView = requireNativeViewManager("ExpoPhotos", "PHImageView");

export function PHImageView({
  requestOptions,
  contentMode,
  ...rest
}: PHImageViewProps) {
  return (
    <NativePHImageView
      viewContentMode={contentMode}
      requestContentMode={requestOptions?.contentMode}
      isNetworkAccessAllowed={requestOptions?.isNetworkAccessAllowed}
      deliveryMode={requestOptions?.deliveryMode}
      resizeMode={requestOptions?.resizeMode}
      targetSize={requestOptions?.targetSize}
      {...rest}
    />
  );
}
