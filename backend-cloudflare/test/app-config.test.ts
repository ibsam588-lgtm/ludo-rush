import { describe, expect, it } from "vitest";
import { buildAppConfig } from "../src/app-config";

describe("app config", () => {
  it("reports the effective iOS minimum that the installed client must compare", () => {
    const body = buildAppConfig({}, "ios", 1701, {
      minimumBuildNumber: 1, latestBuildNumber: 1901, forceLatestBuild: true,
    });
    expect(body.forceUpdate).toBe(true);
    expect(body.minimumBuildNumber).toBe(1901);
    expect(body.latestBuildNumber).toBe(1901);
    expect(buildAppConfig({}, "ios", 1901, {
      minimumBuildNumber: 1, latestBuildNumber: 1901, forceLatestBuild: true,
    }).forceUpdate).toBe(false);
  });

  it("keeps the explicit iOS minimum during staged rollouts", () => {
    const body = buildAppConfig({}, "ios", 1701, {
      minimumBuildNumber: 1701, latestBuildNumber: 1901, forceLatestBuild: false,
    });
    expect(body.forceUpdate).toBe(false);
    expect(body.minimumBuildNumber).toBe(1701);
  });

  it("sends Sandbox testers to TestFlight instead of an unpublished App Store listing", () => {
    const body = buildAppConfig({ APP_STORE_ENVIRONMENT: "Sandbox" }, "ios", 1701, {
      minimumBuildNumber: 1901, updateUrl: "https://apps.apple.com/app/id6834993861",
    });
    expect(body.forceUpdate).toBe(true);
    expect(body.updateUrl).toBe("https://apps.apple.com/app/testflight/id899247664");
    expect(body.message).toContain("select Ludo Cheer");
    expect(buildAppConfig({}, "ios", 1701, { minimumBuildNumber: 1901 }).updateUrl)
      .toBe("https://apps.apple.com/app/id6834993861");
  });

  it("does not block the current iOS build or an unknown development build", () => {
    const policy = { minimumBuildNumber: 1901, latestBuildNumber: 1901, forceLatestBuild: true };
    for (const build of [0, 1901, 2001]) expect(buildAppConfig({}, "ios", build, policy).forceUpdate).toBe(false);
  });

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
