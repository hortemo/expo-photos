import type { ImageSourcePropType } from "react-native";
import {
  PHImageContentMode,
  PHImageRequestOptionsDeliveryMode,
  PHImageRequestOptionsResizeMode,
  RequestImageTargetSize,
} from "./ExpoPhotos.types";

export interface PHImageSourceOptions {
  localIdentifier: string;
  targetSize?: RequestImageTargetSize;
  resizeMode?: PHImageRequestOptionsResizeMode;
  deliveryMode?: PHImageRequestOptionsDeliveryMode;
  contentMode?: PHImageContentMode;
  isNetworkAccessAllowed?: boolean;
}

const buildQueryString = (
  params: Record<string, string | number | boolean | undefined>
): string => {
  const entries = Object.entries(params).filter(
    ([, value]) => value !== undefined
  );

  if (entries.length === 0) {
    return "";
  }

  return (
    "?" +
    entries
      .map(
        ([key, value]) =>
          `${encodeURIComponent(key)}=${encodeURIComponent(value ?? "")}`
      )
      .join("&")
  );
};

/**
 * Creates a source object for React Native's Image component from a Photos library asset identifier.
 *
 * @param options - Configuration for image source, including the local identifier
 * @returns A source object that can be used with the Image component's `source` prop, or undefined if no identifier is provided
 *
 * @example
 * ```tsx
 * import { Image } from 'react-native';
 * import { createPHImageSource } from '@hortemo/expo-photos';
 *
 * <Image
 *   source={createPHImageSource({
 *     localIdentifier: asset.localIdentifier,
 *     targetSize: { width: 200, height: 200 },
 *     contentMode: PHImageContentMode.aspectFill,
 *   })}
 * />
 * ```
 */
export function createPHImageSource(
  options: PHImageSourceOptions
): ImageSourcePropType {
  const {
    localIdentifier,
    resizeMode,
    deliveryMode,
    contentMode,
    isNetworkAccessAllowed,
  } = options;

  const targetSize =
    options.targetSize && typeof options.targetSize === "object"
      ? `${options.targetSize.width}x${options.targetSize.height}`
      : options.targetSize;

  const query = buildQueryString({
    localIdentifier,
    targetSize,
    resizeMode,
    deliveryMode,
    contentMode,
    isNetworkAccessAllowed,
  });

  return { uri: `expo-photos://${query}` };
}
