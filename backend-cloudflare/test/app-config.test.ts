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

  it("requires the latest Play Store build even when minimum is lower by default", async () => {
    const body = buildAppConfig(
      {
        MIN_ANDROID_BUILD_NUMBER: "3",
        LATEST_ANDROID_BUILD_NUMBER: "9"
      },
      "android",
      8
    );

    expect(body.forceUpdate).toBe(true);
    expect(body.minimumBuildNumber).toBe(9);
  });

  it("can opt out of latest-only enforcement for staged rollouts", async () => {
    const body = buildAppConfig(
      {
        FORCE_LATEST_ANDROID_BUILD: "false",
        MIN_ANDROID_BUILD_NUMBER: "3",
        LATEST_ANDROID_BUILD_NUMBER: "9"
      },
      "android",
      8
    );

    expect(body.forceUpdate).toBe(false);
    expect(body.minimumBuildNumber).toBe(3);
    expect(body.latestBuildNumber).toBe(9);
  });

  it("prefers the release published by the Play upload workflow", () => {
    const body = buildAppConfig(
      {
        MIN_ANDROID_BUILD_NUMBER: "1",
        LATEST_ANDROID_BUILD_NUMBER: "1"
      },
      "android",
      10042,
      {
        minimumBuildNumber: 10043,
        latestBuildNumber: 10043,
        latestVersionName: "1.0.43",
        forceLatestBuild: true
      }
    );

    expect(body.forceUpdate).toBe(true);
    expect(body.minimumBuildNumber).toBe(10043);
    expect(body.latestBuildNumber).toBe(10043);
    expect(body.latestVersionName).toBe("1.0.43");
  });
});
