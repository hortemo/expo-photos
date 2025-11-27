import React, { JSX, useCallback, useState } from "react";
import { Button, SafeAreaView, ScrollView, Text, View } from "react-native";
import * as FileSystem from "expo-file-system";
import ExpoPhotos, {
  AVAssetExportPreset,
  AVFileType,
  PHAccessLevel,
  PHAssetMediaType,
  PHAuthorizationStatus,
  PHImageContentMode,
  PHImageRequestOptionsDeliveryMode,
} from "@hortemo/expo-photos";

type TestState = "idle" | "running" | "success" | "error";

type ProgressLog = {
  id: string;
  message: string;
};

type TestStatus = {
  state: TestState;
  error: string | null;
  progress: ProgressLog[];
};

const startStatus: TestStatus = {
  state: "idle",
  error: null,
  progress: [],
};

function ensureWritableFile(filename: string): FileSystem.File {
  const directory = FileSystem.Paths.cache;
  directory.create({ intermediates: true, idempotent: true });
  return new FileSystem.File(directory, filename);
}

function App(): JSX.Element {
  const [status, setStatus] = useState<TestStatus>(startStatus);

  const logProgress = useCallback((id: string, message: string) => {
    console.log(message);
    setStatus((prev) => ({
      ...prev,
      progress: [...prev.progress, { id, message }],
    }));
  }, []);

  const runTests = useCallback(async () => {
    setStatus({ state: "running", error: null, progress: [] });

    try {
      logProgress("request-permission", "Requesting photo library permission...");
      const status = await ExpoPhotos.requestAuthorization(
        PHAccessLevel.readWrite
      );
      if (status !== PHAuthorizationStatus.authorized) {
        throw new Error("Photo library access not granted");
      }
      logProgress(
        "authorization-status",
        `Authorization status: ${PHAuthorizationStatus[status]}`
      );

      logProgress("fetch-images", "Fetching image assets from Photos...");
      const imageAssets = await ExpoPhotos.fetchAssets({
        fetchLimit: 5,
        predicate: `mediaType == ${PHAssetMediaType.Image}`,
      });
      logProgress(
        "image-count",
        `Fetched ${imageAssets.length} image asset(s).`
      );

      const imageAsset = imageAssets[0];
      if (!imageAsset) {
        throw new Error("No image assets available in the photo library");
      }

      const imageOutput = ensureWritableFile("expo-photos-e2e.webp");
      if (imageOutput.exists) {
        imageOutput.delete();
      }

      logProgress(
        "export-image",
        `Exporting image to ${imageOutput.uri}...`
      );
      await ExpoPhotos.requestImage({
        localIdentifier: imageAsset.localIdentifier,
        targetSize: { width: 512, height: 512 },
        contentMode: PHImageContentMode.aspectFit,
        deliveryMode: PHImageRequestOptionsDeliveryMode.HighQualityFormat,
        encodeCompressionQuality: 0.8,
        outputURL: imageOutput.uri,
      });

      const imageInfo = imageOutput.info();
      if (!imageInfo.exists || (imageInfo.size ?? 0) === 0) {
        throw new Error("Image export failed (file missing or empty)");
      }
      logProgress(
        "image-exported",
        `Image exported (${Math.round((imageInfo.size ?? 0) / 1024)} KB).`
      );

      logProgress("fetch-videos", "Fetching video assets from Photos...");
      const videoAssets = await ExpoPhotos.fetchAssets({
        fetchLimit: 5,
        predicate: `mediaType == ${PHAssetMediaType.Video}`,
      });
      logProgress(
        "video-count",
        `Fetched ${videoAssets.length} video asset(s).`
      );

      const videoAsset = videoAssets[0];
      if (!videoAsset) {
        throw new Error("No video assets available in the photo library");
      }

      const videoOutput = ensureWritableFile("expo-photos-e2e.mov");
      if (videoOutput.exists) {
        videoOutput.delete();
      }

      logProgress(
        "export-video",
        `Exporting video ${videoAsset.localIdentifier}...`
      );
      await ExpoPhotos.requestVideo({
        localIdentifier: videoAsset.localIdentifier,
        exportPreset: AVAssetExportPreset.MediumQuality,
        outputFileType: AVFileType.mov,
        outputURL: videoOutput.uri,
        timeout: 20_000,
      });
      const videoInfo = videoOutput.info();
      if (!videoInfo.exists || (videoInfo.size ?? 0) === 0) {
        throw new Error("Video export failed (file missing or empty)");
      }
      logProgress(
        "video-exported",
        `Video exported (${Math.round((videoInfo.size ?? 0) / 1024)} KB).`
      );

      setStatus((prev) => ({
        ...prev,
        state: "success",
        error: null,
      }));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logProgress("error", `Error: ${message}`);
      setStatus((prev) => ({
        ...prev,
        state: "error",
        error: message,
      }));
    }
  }, [logProgress]);

  const isRunning = status.state === "running";

  return (
    <SafeAreaView style={{ flex: 1 }}>
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        contentContainerStyle={{ padding: 16, gap: 16 }}
      >
        <View>
          <Text
            testID="test-status"
            style={{ fontSize: 18, fontWeight: "600" }}
          >
            Status: {status.state}
          </Text>
          {status.error ? (
            <Text testID="test-error">Error: {status.error}</Text>
          ) : null}
          <View style={{ marginTop: 8, gap: 4 }}>
            {status.progress.map((entry, index) => (
              <Text key={entry.id + index} testID={`test-progress-${entry.id}`}>
                {entry.message}
              </Text>
            ))}
          </View>
        </View>

        <Button
          title={isRunning ? "Running..." : "Run tests"}
          onPress={runTests}
          disabled={isRunning}
          testID="run-tests"
        />
      </ScrollView>
    </SafeAreaView>
  );
}

export default App;
