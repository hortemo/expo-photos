# @hortemo/expo-photos

Lightweight wrapper for iOS PhotoKit helpers.

## Installation

```sh
npm install @hortemo/expo-photos
```

## API Reference

- `fetchAssets(options: FetchAssetsOptions): Promise<PHAsset[]>`
- `requestImage(options: RequestImageOptions): Promise<void>`
- `requestVideo(options: RequestVideoOptions): Promise<void>`
- `pickAssets(options: PickAssetsOptions): Promise<PHAsset[]>`
- `requestAuthorization(accessLevel: PHAccessLevel): Promise<PHAuthorizationStatus>`
- `presentLimitedLibraryPicker(): Promise<void>`
