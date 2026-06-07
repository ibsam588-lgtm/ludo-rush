using UnityEngine;
using UnityEngine.UI;

namespace LudoRush.Game
{
    public sealed class InternalTestHud : MonoBehaviour
    {
        [SerializeField] private LudoGameController controller;

        private Text statusText;

        private void Start()
        {
            if (controller == null)
            {
                controller = FindFirstObjectByType<LudoGameController>();
            }

            BuildHud();
        }

        private void Update()
        {
            if (statusText == null || controller == null)
            {
                return;
            }

            var snapshot = controller.LatestSnapshot;
            if (snapshot == null)
            {
                statusText.text = "Ludo Rush internal test";
                return;
            }

            var dice = snapshot.diceValue == 0 ? "-" : snapshot.diceValue.ToString();
            statusText.text = $"Room: {snapshot.roomId}\nStatus: {snapshot.status}\nTurn seat: {snapshot.currentTurnSeat}\nDice: {dice}\nMoves: {MoveCount(snapshot)}";
        }

        private void BuildHud()
        {
            var canvas = new GameObject("InternalTestCanvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvasComponent = canvas.GetComponent<Canvas>();
            canvasComponent.renderMode = RenderMode.ScreenSpaceOverlay;

            var scaler = canvas.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080f, 1920f);

            var panel = new GameObject("Panel", typeof(RectTransform), typeof(Image)).GetComponent<RectTransform>();
            panel.SetParent(canvas.transform, false);
            panel.anchorMin = new Vector2(0f, 1f);
            panel.anchorMax = new Vector2(0f, 1f);
            panel.pivot = new Vector2(0f, 1f);
            panel.sizeDelta = new Vector2(360f, 520f);
            panel.anchoredPosition = new Vector2(24f, -24f);
            panel.GetComponent<Image>().color = new Color(0.06f, 0.07f, 0.1f, 0.86f);

            statusText = CreateText(panel, "Status", new Vector2(24f, -24f), new Vector2(312f, 150f), 24);
            CreateButton(panel, "Quick", new Vector2(24f, -190f), () => controller.StartGuestQuickMatch());
            CreateButton(panel, "Bots", new Vector2(188f, -190f), () => controller.StartBotMatch());
            CreateButton(panel, "Private", new Vector2(24f, -280f), () => controller.CreatePrivateRoom());
            CreateButton(panel, "Roll", new Vector2(188f, -280f), () => controller.RollDice());
            CreateButton(panel, "Move", new Vector2(24f, -370f), () => controller.MoveFirstAvailablePiece());
        }

        private Button CreateButton(RectTransform parent, string label, Vector2 position, UnityEngine.Events.UnityAction action)
        {
            var buttonRect = new GameObject(label, typeof(RectTransform), typeof(Image), typeof(Button)).GetComponent<RectTransform>();
            buttonRect.SetParent(parent, false);
            buttonRect.anchorMin = new Vector2(0f, 1f);
            buttonRect.anchorMax = new Vector2(0f, 1f);
            buttonRect.pivot = new Vector2(0f, 1f);
            buttonRect.sizeDelta = new Vector2(140f, 64f);
            buttonRect.anchoredPosition = position;

            var image = buttonRect.GetComponent<Image>();
            image.color = new Color(0.15f, 0.64f, 0.92f, 0.95f);

            var button = buttonRect.GetComponent<Button>();
            button.onClick.AddListener(action);

            CreateText(buttonRect, label, Vector2.zero, buttonRect.sizeDelta, 24, TextAnchor.MiddleCenter);
            return button;
        }

        private Text CreateText(RectTransform parent, string label, Vector2 position, Vector2 size, int fontSize, TextAnchor anchor = TextAnchor.UpperLeft)
        {
            var textRect = new GameObject($"{label}Text", typeof(RectTransform), typeof(Text)).GetComponent<RectTransform>();
            textRect.SetParent(parent, false);
            textRect.anchorMin = new Vector2(0f, 1f);
            textRect.anchorMax = new Vector2(0f, 1f);
            textRect.pivot = new Vector2(0f, 1f);
            textRect.sizeDelta = size;
            textRect.anchoredPosition = position;

            var text = textRect.GetComponent<Text>();
            text.text = label;
            text.color = Color.white;
            text.fontSize = fontSize;
            text.alignment = anchor;
            text.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
            return text;
        }

        private static int MoveCount(LudoRoomSnapshot snapshot)
        {
            return snapshot.availableMoves == null ? 0 : snapshot.availableMoves.Length;
        }
    }
}
