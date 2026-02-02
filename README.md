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

#### PHImage

A native image component that displays photos from the Photos library using `PHImageManager`.

```tsx
import { PHImage, PHImageContentMode } from "@hortemo/expo-photos";

<PHImage
  localIdentifier={asset.localIdentifier}
  contentMode={PHImageContentMode.aspectFill}
  resizeMode={PHImageRequestOptionsResizeMode.Fast}
  deliveryMode={PHImageRequestOptionsDeliveryMode.HighQualityFormat}
  style={{ width: 300, height: 300 }}
/>
```

#### PHVideo

A video player component that streams videos from the library.

```tsx
import { PHVideo, PHVideoRequestOptionsDeliveryMode } from "@hortemo/expo-photos";

<PHVideo
  localIdentifier={asset.localIdentifier}
  isNetworkAccessAllowed={true}
  deliveryMode={PHVideoRequestOptionsDeliveryMode.Automatic}
  onLoad={(event) => console.log(event.nativeEvent)}
  onError={(event) => console.log(event.nativeEvent.message)}
  style={{ width: 300, height: 200 }}
/>
```
