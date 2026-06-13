using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace LudoRush.Game
{
    public sealed class InternalTestHud : MonoBehaviour
    {
        [SerializeField] private LudoGameController controller;
        [SerializeField] private LudoBoardPresenter boardPresenter;

        private const float ReferenceWidth = 1080f;
        private const float ReferenceHeight = 2400f;

        private Canvas canvas;
        private RectTransform homeRoot;
        private RectTransform gameRoot;
        private RectTransform boardSlot;
        private Text statusText;
        private Text homeStatusText;
        private Text diceText;
        private Text roomText;
        private bool darkMode = true;

        private readonly Color gold = Color32(255, 212, 38);
        private readonly Color amber = Color32(255, 154, 0);
        private readonly Color pink = Color32(255, 79, 163);
        private readonly Color purple = Color32(106, 37, 184);
        private readonly Color blue = Color32(32, 152, 232);
        private readonly Color green = Color32(39, 184, 75);
        private readonly Color red = Color32(243, 50, 44);
        private readonly Color cyan = Color32(50, 211, 200);
        private readonly Color ink = Color32(37, 16, 47);

        private void Start()
        {
            if (controller == null)
            {
                controller = FindFirstObjectByType<LudoGameController>();
            }

            if (boardPresenter == null)
            {
                boardPresenter = FindFirstObjectByType<LudoBoardPresenter>();
            }

            BuildUi();
            WireBoard();
            ShowHome();

            if (controller != null)
            {
                controller.StatusChanged += UpdateStatus;
                UpdateStatus(controller.StatusMessage);
            }
        }

        private void Update()
        {
            if (controller == null)
            {
                return;
            }

            var snapshot = controller.LatestSnapshot;
            if (snapshot != null && !gameRoot.gameObject.activeSelf)
            {
                ShowGame();
            }

            if (diceText != null)
            {
                var dice = controller.LastRollValue;
                diceText.text = dice > 0 ? dice.ToString() : "ROLL";
                diceText.fontSize = dice > 0 ? 72 : 34;
            }

            if (roomText != null)
            {
                roomText.text = snapshot == null
                    ? "Ludo Rush"
                    : $"Room {ShortRoom(snapshot.roomId)} | Seat {snapshot.currentTurnSeat + 1}";
            }
        }

        private void OnDestroy()
        {
            if (controller != null)
            {
                controller.StatusChanged -= UpdateStatus;
            }
        }

        private void BuildUi()
        {
            EnsureEventSystem();

            var canvasObject = new GameObject("LudoRushMobileCanvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 10;

            var scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(ReferenceWidth, ReferenceHeight);
            scaler.matchWidthOrHeight = 0.5f;

            homeRoot = CreateRoot("HomeRoot");
            gameRoot = CreateRoot("GameRoot");

            BuildHome();
            BuildGame();
        }

        private static void EnsureEventSystem()
        {
            if (FindFirstObjectByType<EventSystem>() != null)
            {
                return;
            }

            new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));
        }

        private RectTransform CreateRoot(string name)
        {
            var root = new GameObject(name, typeof(RectTransform)).GetComponent<RectTransform>();
            root.SetParent(canvas.transform, false);
            root.anchorMin = Vector2.zero;
            root.anchorMax = Vector2.one;
            root.offsetMin = Vector2.zero;
            root.offsetMax = Vector2.zero;
            return root;
        }

        private void BuildHome()
        {
            var bg = new GameObject("HomeGradient", typeof(RectTransform), typeof(RushGradientGraphic)).GetComponent<RectTransform>();
            Stretch(bg, homeRoot);
            ApplyHomeGradient(bg.GetComponent<RushGradientGraphic>());

            BuildConfetti(homeRoot, darkMode);
            BuildTopResources(homeRoot, false);

            var title = CreateText(homeRoot, "LUDO RUSH", 38, gold, FontStyle.Bold, TextAnchor.MiddleCenter);
            Place(title.rectTransform, 42, 250, 996, 88);
            title.GetComponent<Shadow>().effectColor = new Color(0f, 0f, 0f, 0.45f);

            var subtitle = CreateText(homeRoot, "GLOBAL MULTIPLAYER MODES", 18, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
            Place(subtitle.rectTransform, 42, 334, 996, 48);

            BuildHeroArt(homeRoot);

            var choose = CreateText(homeRoot, "CHOOSE MODE", 20, darkMode ? gold : ink, FontStyle.Bold, TextAnchor.MiddleLeft);
            Place(choose.rectTransform, 46, 904, 988, 50);

            BuildModeDeck(homeRoot);
            BuildFeatureStrip(homeRoot);
            BuildBottomNav(homeRoot);

            homeStatusText = CreateText(homeRoot, "", 16, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
            Place(homeStatusText.rectTransform, 42, 1990, 996, 64);
        }

        private void BuildTopResources(RectTransform root, bool game)
        {
            var topColor = darkMode ? Color32(64, 16, 79) : pink;
            var top = CreatePanel(root, "TopBar", 0, 0, ReferenceWidth, 176, topColor, 0.92f);
            top.GetComponent<Image>().raycastTarget = false;

            if (game)
            {
                var back = CreateButton(root, "HOME", 24, 66, 134, 74, Color32(42, 10, 54), Color.white);
                back.onClick.AddListener(ShowHome);

                var title = CreateText(root, "LUDO RUSH", 24, gold, FontStyle.Bold, TextAnchor.MiddleCenter);
                Place(title.rectTransform, 220, 72, 640, 62);

                var gameToggle = CreateButton(root, darkMode ? "LIGHT" : "DARK", 918, 66, 134, 74, darkMode ? Color32(42, 10, 54) : purple, Color.white);
                gameToggle.onClick.AddListener(ToggleTheme);
                return;
            }

            CreateResourcePill(root, "XP", "343/500", 28, 66, 270, 74, gold);
            var coins = controller?.Player == null ? "500" : controller.Player.coins.ToString();
            CreateResourcePill(root, "$", coins, 324, 66, 270, 74, Color32(255, 185, 40));
            CreateResourcePill(root, "+", "34", 620, 66, 270, 74, Color32(90, 242, 77));

            var label = darkMode ? "LIGHT" : "DARK";
            var toggle = CreateButton(root, label, 918, 66, 134, 74, darkMode ? Color32(42, 10, 54) : purple, Color.white);
            toggle.onClick.AddListener(ToggleTheme);
        }

        private void CreateResourcePill(RectTransform root, string label, string value, float x, float y, float w, float h, Color accent)
        {
            var pill = CreatePanel(root, $"Pill_{label}", x, y, w, h, darkMode ? Color32(43, 11, 56) : Color.white, 0.92f);
            AddOutline(pill, darkMode ? new Color(1f, 1f, 1f, 0.28f) : new Color(0.49f, 0.30f, 1f, 0.55f), 2.5f);

            var left = CreateText(pill, label, 19, accent, FontStyle.Bold, TextAnchor.MiddleCenter);
            Place(left.rectTransform, 0, 0, 80, h);
            var right = CreateText(pill, value, 20, darkMode ? Color.white : ink, FontStyle.Bold, TextAnchor.MiddleLeft);
            Place(right.rectTransform, 78, 0, w - 86, h);
        }

        private void BuildHeroArt(RectTransform root)
        {
            var phone = CreatePanel(root, "HeroPhone", 340, 388, 400, 420, darkMode ? Color32(49, 32, 74) : Color32(49, 32, 74), 1f);
            AddShadow(phone, 0.45f, 10f);

            var screen = CreatePanel(phone, "PhoneScreen", 40, 54, 320, 310, darkMode ? Color32(122, 37, 95) : Color32(255, 111, 184), 1f);
            AddOutline(screen, new Color(1f, 1f, 1f, 0.18f), 2f);

            var mascot = new GameObject("Mascot", typeof(RectTransform), typeof(RushCircleGraphic)).GetComponent<RectTransform>();
            mascot.SetParent(phone, false);
            Place(mascot, 112, 72, 176, 118);
            mascot.GetComponent<RushCircleGraphic>().color = Color32(255, 48, 96);
            CreateCircle(phone, "EyeLeft", 154, 104, 34, Color.white);
            CreateCircle(phone, "EyeRight", 224, 104, 34, Color.white);
            CreateCircle(phone, "PupilLeft", 165, 114, 14, ink);
            CreateCircle(phone, "PupilRight", 235, 114, 14, ink);

            CreateBoardIcon(screen, 70, 174, 180);
            CreateDice(root, 738, 424, 78, "5", gold);
            CreateDice(root, 300, 548, 62, "3", red);
        }

        private void BuildModeDeck(RectTransform root)
        {
            CreateModeCard(root, "PVT", "PRIVATE\nTABLE", 116, 1092, 210, 430, blue, () => StartPrivate());
            CreateModeCard(root, "VS", "TEAM\nUP", 252, 1040, 220, 420, red, () => StartQuick());
            CreateModeCard(root, "2", "1 ON 1", 380, 988, 320, 544, gold, () => StartQuick());
            CreateModeCard(root, "4", "4 PLAYER", 608, 1040, 220, 420, green, () => StartQuick());
            CreateModeCard(root, "AI", "PLAY\nOFFLINE", 754, 1092, 210, 430, Color32(242, 240, 247), () => StartBots());
        }

        private void CreateModeCard(RectTransform root, string mark, string label, float x, float y, float w, float h, Color color, UnityEngine.Events.UnityAction action)
        {
            var button = CreateButton(root, "", x, y, w, h, color, Color.white);
            button.GetComponent<Image>().color = color;
            AddOutline(button.GetComponent<RectTransform>(), gold, 4f);
            AddShadow(button.GetComponent<RectTransform>(), 0.32f, 8f);
            button.onClick.AddListener(action);

            CreateBoardIcon(button.GetComponent<RectTransform>(), w * 0.22f, 50f, w * 0.58f);
            CreateDice(button.GetComponent<RectTransform>(), w * 0.16f, h * 0.38f, 44f, "3", red);
            CreateDice(button.GetComponent<RectTransform>(), w * 0.62f, h * 0.38f, 40f, "6", gold);

            var markColor = mark == "AI" || mark == "2" ? Color32(157, 17, 91) : Color.white;
            var markText = CreateText(button.GetComponent<RectTransform>(), mark, mark == "2" ? 78 : 42, markColor, FontStyle.Bold, TextAnchor.MiddleCenter);
            Place(markText.rectTransform, 0, h * 0.50f, w, h * 0.20f);

            var labelText = CreateText(button.GetComponent<RectTransform>(), label, mark == "2" ? 24 : 20, mark == "2" || mark == "AI" ? ink : Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
            Place(labelText.rectTransform, 10, h * 0.72f, w - 20, h * 0.22f);
        }

        private void BuildFeatureStrip(RectTransform root)
        {
            CreateFeature(root, "GLOBAL", "MATCHES", 38, 1608, 306, 132, cyan);
            CreateFeature(root, "PRIVATE", "ROOMS", 386, 1608, 306, 132, gold);
            CreateFeature(root, "VOICE", "READY", 734, 1608, 306, 132, Color32(255, 91, 200));
        }

        private void CreateFeature(RectTransform root, string top, string bottom, float x, float y, float w, float h, Color accent)
        {
            var panel = CreatePanel(root, $"Feature_{top}", x, y, w, h, darkMode ? Color32(43, 11, 56) : Color.white, 0.82f);
            AddOutline(panel, darkMode ? new Color(1f, 1f, 1f, 0.34f) : new Color(0.49f, 0.30f, 1f, 0.65f), 2.5f);
            var t = CreateText(panel, top, 20, accent, FontStyle.Bold, TextAnchor.MiddleCenter);
            Place(t.rectTransform, 0, 28, w, 36);
            var b = CreateText(panel, bottom, 18, darkMode ? Color.white : ink, FontStyle.Bold, TextAnchor.MiddleCenter);
            Place(b.rectTransform, 0, 68, w, 36);
        }

        private void BuildBottomNav(RectTransform root)
        {
            var bar = CreatePanel(root, "BottomNav", 0, 2164, ReferenceWidth, 236, darkMode ? Color32(107, 37, 95) : purple, 0.95f);
            bar.GetComponent<Image>().raycastTarget = false;
            CreateNavItem(root, "$", "Shop", 22, false);
            CreateNavItem(root, "FR", "Friends", 236, false);
            CreateNavItem(root, "H", "Home", 450, true);
            CreateNavItem(root, "CL", "Collect", 664, false);
            CreateNavItem(root, "C", "Chest", 878, false);
        }

        private void CreateNavItem(RectTransform root, string icon, string label, float x, bool active)
        {
            var panel = CreatePanel(root, $"Nav_{label}", x, 2200, 180, 144, active ? gold : new Color(1f, 1f, 1f, 0f), active ? 1f : 0f);
            if (active)
            {
                AddOutline(panel, new Color(1f, 1f, 1f, 0.72f), 2.5f);
            }

            var iconText = CreateText(panel, icon, active ? 30 : 24, active ? Color32(110, 24, 57) : Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
            Place(iconText.rectTransform, 0, 18, 180, 42);
            var labelText = CreateText(panel, label, 17, active ? Color32(110, 24, 57) : Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
            Place(labelText.rectTransform, 0, 66, 180, 34);
        }

        private void BuildGame()
        {
            var bg = new GameObject("GameGradient", typeof(RectTransform), typeof(RushGradientGraphic)).GetComponent<RectTransform>();
            Stretch(bg, gameRoot);
            ApplyGameGradient(bg.GetComponent<RushGradientGraphic>());

            BuildTopResources(gameRoot, true);
            BuildSeatPanel(gameRoot, 28, 196, 492, 104, 1, blue);
            BuildSeatPanel(gameRoot, 560, 196, 492, 104, 2, gold);

            statusText = CreateText(gameRoot, "Choose a mode to start.", 22, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
            var statusPanel = CreatePanel(gameRoot, "StatusPanel", 36, 332, 1008, 84, pink, 0.78f);
            AddOutline(statusPanel, gold, 3f);
            statusText.transform.SetParent(statusPanel, false);
            Stretch(statusText.rectTransform, statusPanel);

            boardSlot = CreatePanel(gameRoot, "BoardSlot", 28, 456, 1024, 1024, new Color(0f, 0f, 0f, 0f), 0f);

            BuildSeatPanel(gameRoot, 28, 1536, 492, 104, 0, red);
            BuildSeatPanel(gameRoot, 560, 1536, 492, 104, 3, green);

            var voice = CreatePanel(gameRoot, "VoiceBanner", 36, 1686, 1008, 76, Color32(21, 74, 154), 1f);
            AddOutline(voice, gold, 2.5f);
            var voiceText = CreateText(voice, "REAL TIME VOICE CHAT", 22, gold, FontStyle.Bold, TextAnchor.MiddleCenter);
            Stretch(voiceText.rectTransform, voice);

            var dicePanel = CreatePanel(gameRoot, "DicePanel", 38, 1812, 206, 206, darkMode ? Color32(43, 11, 56) : Color.white, 0.92f);
            AddOutline(dicePanel, gold, 3f);
            diceText = CreateText(dicePanel, "ROLL", 34, darkMode ? Color.white : ink, FontStyle.Bold, TextAnchor.MiddleCenter);
            Stretch(diceText.rectTransform, dicePanel);

            var roll = CreateButton(gameRoot, "Roll Dice", 274, 1812, 770, 104, gold, ink);
            roll.GetComponent<Image>().color = amber;
            roll.onClick.AddListener(() => controller?.RollDice());

            var best = CreateButton(gameRoot, "Best Move", 274, 1940, 374, 92, cyan, Color.white);
            best.onClick.AddListener(() => controller?.MoveFirstAvailablePiece());

            var resign = CreateButton(gameRoot, "Home", 670, 1940, 374, 92, darkMode ? Color32(80, 15, 104) : Color.white, red);
            AddOutline(resign.GetComponent<RectTransform>(), red, 2.5f);
            resign.onClick.AddListener(ShowHome);

            roomText = CreateText(gameRoot, "Ludo Rush", 15, darkMode ? Color.white : ink, FontStyle.Bold, TextAnchor.MiddleCenter);
            Place(roomText.rectTransform, 38, 2052, 1004, 44);
        }

        private void BuildSeatPanel(RectTransform root, float x, float y, float w, float h, int seat, Color seatColor)
        {
            var panel = CreatePanel(root, $"Seat_{seat}", x, y, w, h, darkMode ? Color32(31, 14, 47) : Color.white, 0.92f);
            AddOutline(panel, gold, 4f);
            var avatar = CreateCircle(panel, "Avatar", 20, 18, 68, seatColor);
            AddOutline(avatar, new Color(1f, 1f, 1f, 0.5f), 1.5f);
            var name = CreateText(panel, $"player {seat + 1}", 21, darkMode ? Color.white : ink, FontStyle.Bold, TextAnchor.MiddleLeft);
            Place(name.rectTransform, 106, 18, w - 190, 36);
            var meta = CreateText(panel, $"Seat {seat + 1}", 16, darkMode ? Color32(255, 236, 168) : Color32(90, 36, 92), FontStyle.Bold, TextAnchor.MiddleLeft);
            Place(meta.rectTransform, 106, 56, w - 190, 28);
            var mic = CreateText(panel, "MIC", 16, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
            Place(mic.rectTransform, w - 90, 22, 72, 58);
        }

        private void WireBoard()
        {
            if (boardPresenter == null)
            {
                return;
            }

            boardPresenter.AttachTo(boardSlot);
            boardPresenter.SetDarkMode(darkMode);
            boardPresenter.SetPieceTapped(pieceId => controller?.MovePiece(pieceId));
        }

        private void ToggleTheme()
        {
            darkMode = !darkMode;
            RebuildAll();
        }

        private void RebuildAll()
        {
            var wasInGame = gameRoot != null && gameRoot.gameObject.activeSelf;

            if (canvas != null)
            {
                Destroy(canvas.gameObject);
            }

            BuildUi();
            WireBoard();
            if (controller?.LatestSnapshot != null)
            {
                boardPresenter?.ApplySnapshot(controller.LatestSnapshot);
            }

            if (wasInGame)
            {
                ShowGame();
            }
            else
            {
                ShowHome();
            }

            UpdateStatus(controller == null ? "Choose a mode to start." : controller.StatusMessage);
        }

        private void ShowHome()
        {
            homeRoot.gameObject.SetActive(true);
            gameRoot.gameObject.SetActive(false);
        }

        private void ShowGame()
        {
            homeRoot.gameObject.SetActive(false);
            gameRoot.gameObject.SetActive(true);
            boardPresenter?.ShowEmptyBoard();
        }

        private void StartQuick()
        {
            ShowGame();
            controller?.StartGuestQuickMatch();
        }

        private void StartBots()
        {
            ShowGame();
            controller?.StartBotMatch();
        }

        private void StartPrivate()
        {
            ShowGame();
            controller?.CreatePrivateRoom();
        }

        private void UpdateStatus(string message)
        {
            if (string.IsNullOrWhiteSpace(message))
            {
                message = "Choose a mode to start.";
            }

            if (statusText != null)
            {
                statusText.text = message;
            }

            if (homeStatusText != null)
            {
                homeStatusText.text = message;
            }
        }

        private void ApplyHomeGradient(RushGradientGraphic graphic)
        {
            if (darkMode)
            {
                graphic.topLeft = Color32(40, 6, 62);
                graphic.topRight = Color32(154, 36, 212);
                graphic.bottomLeft = Color32(19, 0, 28);
                graphic.bottomRight = Color32(49, 16, 75);
            }
            else
            {
                graphic.topLeft = pink;
                graphic.topRight = Color32(255, 217, 90);
                graphic.bottomLeft = Color32(64, 216, 255);
                graphic.bottomRight = Color32(141, 76, 255);
            }
        }

        private void ApplyGameGradient(RushGradientGraphic graphic)
        {
            if (darkMode)
            {
                graphic.topLeft = Color32(21, 0, 32);
                graphic.topRight = Color32(77, 15, 105);
                graphic.bottomLeft = Color32(21, 0, 32);
                graphic.bottomRight = Color32(42, 11, 73);
            }
            else
            {
                graphic.topLeft = Color32(255, 240, 251);
                graphic.topRight = Color32(255, 225, 90);
                graphic.bottomLeft = Color32(64, 216, 255);
                graphic.bottomRight = Color32(141, 76, 255);
            }
        }

        private void BuildConfetti(RectTransform root, bool dark)
        {
            var colors = dark
                ? new[] {gold, Color32(85, 255, 77), cyan, Color32(255, 91, 200), Color.white}
                : new[] {purple, Color32(255, 47, 126), Color32(24, 191, 245), Color32(32, 216, 107), gold};

            for (var i = 0; i < 44; i++)
            {
                var x = (i * 97 + 41) % 1000 / 1000f * ReferenceWidth;
                var y = 190f + ((i * 61 + 87) % 1460);
                var rect = CreatePanel(root, $"Confetti_{i}", x, y, 22, 7, colors[i % colors.Length], 1f);
                rect.localRotation = Quaternion.Euler(0f, 0f, (i * 31) % 180);
            }
        }

        private RectTransform CreateBoardIcon(RectTransform parent, float x, float y, float size)
        {
            var board = CreatePanel(parent, "MiniBoard", x, y, size, size, Color32(255, 246, 208), 1f);
            var half = size / 2f;
            CreatePanel(board, "Red", 0, 0, half, half, red, 1f);
            CreatePanel(board, "Yellow", half, 0, half, half, gold, 1f);
            CreatePanel(board, "Blue", 0, half, half, half, Color32(31, 107, 218), 1f);
            CreatePanel(board, "Green", half, half, half, half, green, 1f);
            CreatePanel(board, "Vertical", half - size * 0.08f, 0, size * 0.16f, size, Color32(255, 246, 208), 1f);
            CreatePanel(board, "Horizontal", 0, half - size * 0.08f, size, size * 0.16f, Color32(255, 246, 208), 1f);
            AddOutline(board, Color.white, 2f);
            return board;
        }

        private RectTransform CreateDice(RectTransform parent, float x, float y, float size, string value, Color color)
        {
            var dice = CreatePanel(parent, "Dice", x, y, size, size, color, 1f);
            AddShadow(dice, 0.25f, 5f);
            var text = CreateText(dice, value, Mathf.RoundToInt(size * 0.42f), color == gold ? ink : Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
            Stretch(text.rectTransform, dice);
            return dice;
        }

        private RectTransform CreateCircle(RectTransform parent, string name, float x, float y, float size, Color color)
        {
            var rect = new GameObject(name, typeof(RectTransform), typeof(RushCircleGraphic)).GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            Place(rect, x, y, size, size);
            rect.GetComponent<RushCircleGraphic>().color = color;
            return rect;
        }

        private Button CreateButton(RectTransform parent, string label, float x, float y, float w, float h, Color bg, Color fg)
        {
            var rect = CreatePanel(parent, $"Button_{label}", x, y, w, h, bg, 1f);
            var button = rect.gameObject.AddComponent<Button>();
            button.transition = Selectable.Transition.ColorTint;

            if (!string.IsNullOrEmpty(label))
            {
                var text = CreateText(rect, label, 19, fg, FontStyle.Bold, TextAnchor.MiddleCenter);
                Stretch(text.rectTransform, rect);
            }

            return button;
        }

        private RectTransform CreatePanel(RectTransform parent, string name, float x, float y, float w, float h, Color color, float alpha)
        {
            var rect = new GameObject(name, typeof(RectTransform), typeof(Image)).GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            Place(rect, x, y, w, h);
            color.a *= alpha;
            var image = rect.GetComponent<Image>();
            image.color = color;
            image.raycastTarget = alpha > 0.001f;
            return rect;
        }

        private Text CreateText(RectTransform parent, string value, int size, Color color, FontStyle style, TextAnchor anchor)
        {
            var rect = new GameObject($"Text_{value}", typeof(RectTransform), typeof(Text), typeof(Shadow)).GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            var text = rect.GetComponent<Text>();
            text.text = value;
            text.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
            text.fontSize = size;
            text.fontStyle = style;
            text.color = color;
            text.alignment = anchor;
            text.horizontalOverflow = HorizontalWrapMode.Wrap;
            text.verticalOverflow = VerticalWrapMode.Truncate;
            text.GetComponent<Shadow>().effectColor = new Color(0f, 0f, 0f, 0.32f);
            text.GetComponent<Shadow>().effectDistance = new Vector2(0f, -2f);
            return text;
        }

        private static void Place(RectTransform rect, float x, float y, float w, float h)
        {
            rect.anchorMin = new Vector2(0f, 1f);
            rect.anchorMax = new Vector2(0f, 1f);
            rect.pivot = new Vector2(0f, 1f);
            rect.anchoredPosition = new Vector2(x, -y);
            rect.sizeDelta = new Vector2(w, h);
        }

        private static void Stretch(RectTransform rect, RectTransform parent)
        {
            rect.SetParent(parent, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
        }

        private static void AddOutline(RectTransform rect, Color color, float distance)
        {
            var outline = rect.gameObject.AddComponent<Outline>();
            outline.effectColor = color;
            outline.effectDistance = new Vector2(distance, -distance);
        }

        private static void AddShadow(RectTransform rect, float alpha, float distance)
        {
            var shadow = rect.gameObject.AddComponent<Shadow>();
            shadow.effectColor = new Color(0f, 0f, 0f, alpha);
            shadow.effectDistance = new Vector2(0f, -distance);
        }

        private static string ShortRoom(string roomId)
        {
            if (string.IsNullOrWhiteSpace(roomId))
            {
                return "--";
            }

            return roomId.Length <= 6 ? roomId : roomId.Substring(0, 6);
        }

        private static Color Color32(byte r, byte g, byte b)
        {
            return new Color32(r, g, b, 255);
        }
    }
}
