import { requireNativeViewManager } from "expo-modules-core";
import { ViewProps } from "react-native";
import {
  PHVideoLoadEvent,
  PHVideoErrorEvent,
  PHVideoRequestOptions,
} from "./ExpoPhotos.types";

export interface PHVideoViewRequestOptions extends PHVideoRequestOptions {}

export interface PHVideoViewProps extends ViewProps {
  localIdentifier: string;
  requestOptions?: PHVideoViewRequestOptions;
  onLoad?: (event: { nativeEvent: PHVideoLoadEvent }) => void;
  onError?: (event: { nativeEvent: PHVideoErrorEvent }) => void;
}

const NativePHVideoView = requireNativeViewManager("ExpoPhotos", "PHVideoView");

export function PHVideoView({ requestOptions, ...rest }: PHVideoViewProps) {
  return (
    <NativePHVideoView
      isNetworkAccessAllowed={requestOptions?.isNetworkAccessAllowed}
      deliveryMode={requestOptions?.deliveryMode}
      {...rest}
    />
  );
}
