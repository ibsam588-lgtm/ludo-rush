using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace LudoRush.Game
{
    public sealed class LudoBoardPresenter : MonoBehaviour
    {
        [SerializeField] private RectTransform boardRoot;
        [SerializeField] private Vector2 boardSize = new Vector2(720f, 720f);
        [SerializeField] private float tokenSize = 34f;
        [SerializeField] private float tileSize = 18f;

        private readonly Dictionary<string, RectTransform> tokens = new Dictionary<string, RectTransform>();
        private readonly List<RectTransform> tiles = new List<RectTransform>();

        private static readonly Color[] SeatColors =
        {
            new Color(0.94f, 0.18f, 0.37f),
            new Color(0.05f, 0.72f, 0.95f),
            new Color(1.0f, 0.79f, 0.16f),
            new Color(0.2f, 0.9f, 0.49f)
        };

        public void ApplySnapshot(LudoRoomSnapshot snapshot)
        {
            if (snapshot == null || snapshot.pieces == null)
            {
                return;
            }

            EnsureBoard();

            foreach (var piece in snapshot.pieces)
            {
                var token = GetOrCreateToken(piece);
                token.anchoredPosition = PositionForPiece(piece);
            }
        }

        private void EnsureBoard()
        {
            if (boardRoot == null)
            {
                boardRoot = transform as RectTransform;
            }

            if (boardRoot == null)
            {
                var canvas = FindFirstObjectByType<Canvas>();
                if (canvas == null)
                {
                    canvas = new GameObject("BoardCanvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster)).GetComponent<Canvas>();
                    canvas.renderMode = RenderMode.ScreenSpaceOverlay;
                    var scaler = canvas.GetComponent<CanvasScaler>();
                    scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
                    scaler.referenceResolution = new Vector2(1080f, 1920f);
                }

                boardRoot = new GameObject("LudoBoard", typeof(RectTransform)).GetComponent<RectTransform>();
                boardRoot.SetParent(canvas.transform, false);
                boardRoot.anchorMin = new Vector2(0.5f, 0.5f);
                boardRoot.anchorMax = new Vector2(0.5f, 0.5f);
                boardRoot.pivot = new Vector2(0.5f, 0.5f);
                boardRoot.anchoredPosition = Vector2.zero;
            }

            if (tiles.Count > 0)
            {
                return;
            }

            boardRoot.sizeDelta = boardSize;

            for (var i = 0; i < 52; i++)
            {
                var tile = new GameObject($"Track_{i}", typeof(RectTransform), typeof(Image)).GetComponent<RectTransform>();
                tile.SetParent(boardRoot, false);
                tile.sizeDelta = new Vector2(tileSize, tileSize);
                tile.anchoredPosition = TrackPosition(i);
                tile.GetComponent<Image>().color = i % 13 == 0
                    ? new Color(1f, 1f, 1f, 0.9f)
                    : new Color(0.18f, 0.2f, 0.26f, 0.55f);
                tiles.Add(tile);
            }

            var center = new GameObject("OrbitCenter", typeof(RectTransform), typeof(Image)).GetComponent<RectTransform>();
            center.SetParent(boardRoot, false);
            center.sizeDelta = new Vector2(120f, 120f);
            center.anchoredPosition = Vector2.zero;
            center.GetComponent<Image>().color = new Color(0.08f, 0.09f, 0.13f, 0.92f);
            tiles.Add(center);
        }

        private RectTransform GetOrCreateToken(LudoPiece piece)
        {
            if (tokens.TryGetValue(piece.pieceId, out var existing))
            {
                return existing;
            }

            var token = new GameObject(piece.pieceId, typeof(RectTransform), typeof(Image)).GetComponent<RectTransform>();
            token.SetParent(boardRoot, false);
            token.sizeDelta = new Vector2(tokenSize, tokenSize);
            token.GetComponent<Image>().color = SeatColors[Mathf.Clamp(piece.seat, 0, SeatColors.Length - 1)];
            tokens[piece.pieceId] = token;
            return token;
        }

        private Vector2 PositionForPiece(LudoPiece piece)
        {
            var pieceIndex = PieceIndex(piece.pieceId);

            if (piece.state == "yard")
            {
                return YardPosition(piece.seat, pieceIndex);
            }

            if (piece.state == "home")
            {
                return HomeLanePosition(piece.seat, piece.progress);
            }

            if (piece.state == "finished")
            {
                return FinishedPosition(piece.seat, pieceIndex);
            }

            return TrackPosition(piece.trackIndex) + TokenOffset(pieceIndex);
        }

        private Vector2 TrackPosition(int trackIndex)
        {
            var half = boardSize.x * 0.43f;
            var step = (half * 2f) / 13f;
            var side = Mathf.FloorToInt(trackIndex / 13f);
            var index = trackIndex % 13;

            switch (side)
            {
                case 0:
                    return new Vector2(-half + index * step, -half);
                case 1:
                    return new Vector2(half, -half + index * step);
                case 2:
                    return new Vector2(half - index * step, half);
                default:
                    return new Vector2(-half, half - index * step);
            }
        }

        private Vector2 YardPosition(int seat, int pieceIndex)
        {
            var half = boardSize.x * 0.34f;
            var corner = seat switch
            {
                0 => new Vector2(-half, -half),
                1 => new Vector2(half, -half),
                2 => new Vector2(half, half),
                _ => new Vector2(-half, half)
            };

            return corner + TokenOffset(pieceIndex) * 1.8f;
        }

        private Vector2 HomeLanePosition(int seat, int progress)
        {
            var t = Mathf.InverseLerp(52f, 56f, progress);
            var outer = TrackPosition(seat * 13);
            return Vector2.Lerp(outer, Vector2.zero, Mathf.Clamp01(t));
        }

        private Vector2 FinishedPosition(int seat, int pieceIndex)
        {
            return TokenOffset(pieceIndex) + new Vector2((seat - 1.5f) * 16f, 0f);
        }

        private Vector2 TokenOffset(int pieceIndex)
        {
            return pieceIndex switch
            {
                0 => new Vector2(-8f, -8f),
                1 => new Vector2(8f, -8f),
                2 => new Vector2(-8f, 8f),
                _ => new Vector2(8f, 8f)
            };
        }

        private static int PieceIndex(string pieceId)
        {
            var index = pieceId.LastIndexOf('p');
            if (index < 0 || index == pieceId.Length - 1)
            {
                return 0;
            }

            return int.TryParse(pieceId.Substring(index + 1), out var value) ? value : 0;
        }
    }
}
