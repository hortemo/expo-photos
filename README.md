# @hortemo/expo-photos

Lightweight Expo (React Native) wrapper for Apple's [Photos](https://developer.apple.com/documentation/photos) framework.

## Installation

```sh
npm install @hortemo/expo-photos
```

## API Reference

### Functions

- `fetchAssets(options: FetchAssetsOptions): Promise<PHAsset[]>`
- `requestImage(options: RequestImageOptions): Promise<void>`
- `requestVideo(options: RequestVideoOptions): Promise<void>`
- `pickAssets(options: PickAssetsOptions): Promise<PHAsset[]>`
- `authorizationStatus(accessLevel: PHAccessLevel): Promise<PHAuthorizationStatus>`
- `requestAuthorization(accessLevel: PHAccessLevel): Promise<PHAuthorizationStatus>`
- `presentLimitedLibraryPicker(): Promise<void>`

### Components

#### PHImageView

A native image component that displays photos from the Photos library using `PHImageManager`.

```tsx
import {
  PHImageView,
  PHImageContentMode,
  PHImageRequestOptionsResizeMode,
  PHImageRequestOptionsDeliveryMode,
  UIViewContentMode,
} from "@hortemo/expo-photos";

<PHImageView
  localIdentifier={asset.localIdentifier}
  contentMode={UIViewContentMode.scaleAspectFill}
  requestOptions={{
    contentMode: PHImageContentMode.aspectFit,
    resizeMode: PHImageRequestOptionsResizeMode.fast,
    deliveryMode: PHImageRequestOptionsDeliveryMode.highQualityFormat,
    targetSize: { width: 300, height: 300 },
    isNetworkAccessAllowed: true,
  }}
  onLoad={(event) => console.log(event.nativeEvent)}
  onError={(event) => console.log(event.nativeEvent.message)}
  style={{ width: 300, height: 300 }}
/>
```

#### PHVideoView

A video player component that streams videos from the library.

```tsx
import { PHVideoView, PHVideoRequestOptionsDeliveryMode } from "@hortemo/expo-photos";

<PHVideoView
  localIdentifier={asset.localIdentifier}
  requestOptions={{
    isNetworkAccessAllowed: true,
    deliveryMode: PHVideoRequestOptionsDeliveryMode.automatic,
  }}
  onLoad={(event) => console.log(event.nativeEvent)}
  onError={(event) => console.log(event.nativeEvent.message)}
  style={{ width: 300, height: 200 }}
/>
```
