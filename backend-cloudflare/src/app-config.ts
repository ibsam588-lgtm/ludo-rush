import type { Env } from "./types";

const PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.ludorush.game";

export interface AppConfigResponse {
  platform: string;
  forceUpdate: boolean;
  minimumBuildNumber: number;
  latestBuildNumber: number;
  latestVersionName: string;
  updateUrl: string;
  message: string;
}

export function buildAppConfig(
  env: Pick<
    Env,
    | "MIN_ANDROID_BUILD_NUMBER"
    | "LATEST_ANDROID_BUILD_NUMBER"
    | "LATEST_ANDROID_VERSION_NAME"
    | "FORCE_LATEST_ANDROID_BUILD"
    | "ANDROID_UPDATE_URL"
    | "FORCE_UPDATE_MESSAGE"
  >,
  platform: string,
  installedBuild: number
): AppConfigResponse {
  const normalizedPlatform = platform.toLowerCase();
  const latestBuildNumber = parsePositiveInt(env.LATEST_ANDROID_BUILD_NUMBER, 1);
  const forceLatestBuild = env.FORCE_LATEST_ANDROID_BUILD !== "false";
  const configuredMinimum = parsePositiveInt(env.MIN_ANDROID_BUILD_NUMBER, latestBuildNumber);
  const minimumBuildNumber = forceLatestBuild
    ? Math.max(latestBuildNumber, configuredMinimum)
    : configuredMinimum;
  const latestVersionName = env.LATEST_ANDROID_VERSION_NAME || "1.0.0";
  const forceUpdate =
    normalizedPlatform === "android" &&
    installedBuild > 0 &&
    installedBuild < minimumBuildNumber;

  return {
    platform: normalizedPlatform,
    forceUpdate,
    minimumBuildNumber,
    latestBuildNumber,
    latestVersionName,
    updateUrl: env.ANDROID_UPDATE_URL || PLAY_STORE_URL,
    message:
      env.FORCE_UPDATE_MESSAGE ||
      "A newer version of Ludo Rush is required to keep matchmaking, rewards, and game rules in sync."
  };
}

export function parsePositiveInt(value: string | null | undefined, fallback: number): number {
  if (!value) {
    return fallback;
  }
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}
