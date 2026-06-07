using System;
using System.IO;
using LudoRush.Core;
using LudoRush.Game;
using LudoRush.Networking;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;

namespace LudoRush.Editor
{
    public static class CiBuild
    {
        private const string ScenePath = "Assets/Scenes/InternalTest.unity";
        private const string ConfigPath = "Assets/Resources/LudoRushConfig.asset";

        public static void BuildAndroidAppBundle()
        {
            PrepareInternalTestScene();
            ConfigureAndroidPlayer();

            var outputDirectory = Path.GetFullPath(Path.Combine("..", "build", "Android"));
            Directory.CreateDirectory(outputDirectory);

            var options = new BuildPlayerOptions
            {
                scenes = new[] { ScenePath },
                locationPathName = Path.Combine(outputDirectory, "LudoRush.aab"),
                target = BuildTarget.Android,
                options = BuildOptions.None
            };

            var report = BuildPipeline.BuildPlayer(options);
            if (report.summary.result != UnityEditor.Build.Reporting.BuildResult.Succeeded)
            {
                throw new InvalidOperationException($"Android build failed: {report.summary.result}");
            }
        }

        private static void PrepareInternalTestScene()
        {
            Directory.CreateDirectory("Assets/Scenes");
            Directory.CreateDirectory("Assets/Resources");

            var config = AssetDatabase.LoadAssetAtPath<LudoRushConfig>(ConfigPath);
            if (config == null)
            {
                config = ScriptableObject.CreateInstance<LudoRushConfig>();
                AssetDatabase.CreateAsset(config, ConfigPath);
            }

            var serializedConfig = new SerializedObject(config);
            serializedConfig.FindProperty("backendBaseUrl").stringValue = Environment.GetEnvironmentVariable("LUDO_RUSH_BACKEND_URL") ?? "http://localhost:8787";
            serializedConfig.FindProperty("defaultRegion").stringValue = Environment.GetEnvironmentVariable("LUDO_RUSH_REGION") ?? "auto";
            serializedConfig.FindProperty("defaultMode").stringValue = Environment.GetEnvironmentVariable("LUDO_RUSH_MODE") ?? "classic_2p";
            serializedConfig.ApplyModifiedPropertiesWithoutUndo();

            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var network = new GameObject("Network");
            var apiClient = network.AddComponent<LudoRushApiClient>();
            var realtimeClient = network.AddComponent<RealtimeRoomClient>();

            SetObject(apiClient, "config", config);

            var canvasObject = new GameObject("GameCanvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080f, 1920f);

            var boardRoot = new GameObject("BoardRoot", typeof(RectTransform)).GetComponent<RectTransform>();
            boardRoot.SetParent(canvasObject.transform, false);
            boardRoot.anchorMin = new Vector2(0.5f, 0.5f);
            boardRoot.anchorMax = new Vector2(0.5f, 0.5f);
            boardRoot.pivot = new Vector2(0.5f, 0.5f);
            boardRoot.sizeDelta = new Vector2(720f, 720f);

            var game = new GameObject("Game");
            var boardPresenter = game.AddComponent<LudoBoardPresenter>();
            var controller = game.AddComponent<LudoGameController>();
            var hud = game.AddComponent<InternalTestHud>();

            SetObject(boardPresenter, "boardRoot", boardRoot);
            SetObject(controller, "apiClient", apiClient);
            SetObject(controller, "realtimeClient", realtimeClient);
            SetObject(controller, "config", config);
            SetObject(controller, "boardPresenter", boardPresenter);
            SetObject(hud, "controller", controller);

            EditorSceneManager.SaveScene(scene, ScenePath);
            AssetDatabase.SaveAssets();
        }

        private static void ConfigureAndroidPlayer()
        {
            EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.Android, BuildTarget.Android);
            EditorUserBuildSettings.buildAppBundle = true;

            var packageName = Environment.GetEnvironmentVariable("ANDROID_PACKAGE_NAME") ?? "com.ludorush.game";
            PlayerSettings.productName = "Ludo Rush";
            PlayerSettings.companyName = "Ludo Rush";
            PlayerSettings.bundleVersion = Environment.GetEnvironmentVariable("APP_VERSION") ?? "0.1.0";
            PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, packageName);
            PlayerSettings.SetScriptingBackend(BuildTargetGroup.Android, ScriptingImplementation.IL2CPP);
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
            PlayerSettings.Android.bundleVersionCode = int.TryParse(Environment.GetEnvironmentVariable("ANDROID_VERSION_CODE"), out var versionCode)
                ? versionCode
                : 1;

            var keystoreBase64 = Environment.GetEnvironmentVariable("UNITY_ANDROID_KEYSTORE_BASE64");
            if (string.IsNullOrWhiteSpace(keystoreBase64))
            {
                Debug.LogWarning("UNITY_ANDROID_KEYSTORE_BASE64 is not set. The build can be created, but Google Play upload needs a release signing setup.");
                return;
            }

            var keystorePath = Path.Combine(Path.GetTempPath(), "ludo-rush-upload.keystore");
            File.WriteAllBytes(keystorePath, Convert.FromBase64String(keystoreBase64));

            PlayerSettings.Android.useCustomKeystore = true;
            PlayerSettings.Android.keystoreName = keystorePath;
            PlayerSettings.Android.keystorePass = Environment.GetEnvironmentVariable("UNITY_ANDROID_KEYSTORE_PASS") ?? "";
            PlayerSettings.Android.keyaliasName = Environment.GetEnvironmentVariable("UNITY_ANDROID_KEYALIAS_NAME") ?? "";
            PlayerSettings.Android.keyaliasPass = Environment.GetEnvironmentVariable("UNITY_ANDROID_KEYALIAS_PASS") ?? "";
        }

        private static void SetObject(UnityEngine.Object target, string fieldName, UnityEngine.Object value)
        {
            var serializedObject = new SerializedObject(target);
            serializedObject.FindProperty(fieldName).objectReferenceValue = value;
            serializedObject.ApplyModifiedPropertiesWithoutUndo();
        }
    }
}
