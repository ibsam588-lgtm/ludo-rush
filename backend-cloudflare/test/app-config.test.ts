import { describe, expect, it } from "vitest";
import { buildAppConfig } from "../src/app-config";

describe("app config", () => {
  it("forces Android builds below the configured minimum", async () => {
    const body = buildAppConfig(
      {
        MIN_ANDROID_BUILD_NUMBER: "5",
        LATEST_ANDROID_BUILD_NUMBER: "5",
        LATEST_ANDROID_VERSION_NAME: "1.0.1"
      },
      "android",
      4
    );

    expect(body.forceUpdate).toBe(true);
    expect(body.minimumBuildNumber).toBe(5);
    expect(body.latestVersionName).toBe("1.0.1");
  });

  it("uses the latest Android build as the minimum when no separate minimum is configured", async () => {
    const body = buildAppConfig(
      {
        LATEST_ANDROID_BUILD_NUMBER: "7"
      },
      "android",
      1
    );

    expect(body.forceUpdate).toBe(true);
    expect(body.minimumBuildNumber).toBe(7);
    expect(body.latestBuildNumber).toBe(7);
  });
});
