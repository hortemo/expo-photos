import { requireNativeViewManager } from "expo-modules-core";
import { ViewProps } from "react-native";
import {
  PHVideoLoadEvent,
  PHVideoErrorEvent,
  PHVideoRequestOptions,
} from "./ExpoPhotos.types";

export interface PHVideoProps extends ViewProps, PHVideoRequestOptions {
  localIdentifier: string;
  onLoad?: (event: { nativeEvent: PHVideoLoadEvent }) => void;
  onError?: (event: { nativeEvent: PHVideoErrorEvent }) => void;
}

const NativePHVideoView = requireNativeViewManager("ExpoPhotos", "PHVideoView");

export function PHVideo(props: PHVideoProps) {
  return <NativePHVideoView {...props} />;
}
