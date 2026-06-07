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

        private readonly Dictionary<string, RectTransform> tokens = new Dictionary<string, RectTransform>();
        private readonly List<RectTransform> tiles = new List<RectTransform>();

        private static readonly Color[] SeatColors =
        {
            new Color(0.91f, 0.16f, 0.24f),
            new Color(0.12f, 0.53f, 0.90f),
            new Color(0.98f, 0.66f, 0.15f),
            new Color(0.26f, 0.63f, 0.28f)
        };

        private static readonly int[,] GridPath =
        {
            {6,14},{6,13},{6,12},{6,11},{6,10},{6,9},{5,8},{4,8},{3,8},{2,8},{1,8},{0,8},{0,7},
            {0,6},{1,6},{2,6},{3,6},{4,6},{5,6},{6,5},{6,4},{6,3},{6,2},{6,1},{6,0},{7,0},
            {8,0},{8,1},{8,2},{8,3},{8,4},{8,5},{9,6},{10,6},{11,6},{12,6},{13,6},{14,6},{14,7},
            {14,8},{13,8},{12,8},{11,8},{10,8},{9,8},{8,9},{8,10},{8,11},{8,12},{8,13},{8,14},{7,14}
        };

        private static readonly int[,,] HomeLanePaths =
        {
            {{7,13},{7,12},{7,11},{7,10},{7,9}},
            {{1,7},{2,7},{3,7},{4,7},{5,7}},
            {{7,1},{7,2},{7,3},{7,4},{7,5}},
            {{13,7},{12,7},{11,7},{10,7},{9,7}}
        };

        private static readonly int[,] BaseCorners = {{0, 9}, {0, 0}, {9, 0}, {9, 9}};
        private static readonly float[,] YardSlots = {{2.1f, 2.1f}, {3.9f, 2.1f}, {2.1f, 3.9f}, {3.9f, 3.9f}};

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
            var cellSize = boardSize.x / 15f;
            var tileGap = 2f;

            for (var i = 0; i < GridPath.GetLength(0); i++)
            {
                var tile = new GameObject($"Track_{i}", typeof(RectTransform), typeof(Image)).GetComponent<RectTransform>();
                tile.SetParent(boardRoot, false);
                tile.sizeDelta = new Vector2(cellSize - tileGap, cellSize - tileGap);
                tile.anchoredPosition = TrackPosition(i);
                var img = tile.GetComponent<Image>();
                var isStart = i == 0 || i == 13 || i == 26 || i == 39;
                img.color = isStart ? SeatColors[i / 13] : new Color(1f, 1f, 1f, 0.95f);
                tiles.Add(tile);
            }

            for (var seat = 0; seat < 4; seat++)
            {
                for (var lane = 0; lane < HomeLanePaths.GetLength(1); lane++)
                {
                    var tile = new GameObject($"Home_{seat}_{lane}", typeof(RectTransform), typeof(Image)).GetComponent<RectTransform>();
                    tile.SetParent(boardRoot, false);
                    tile.sizeDelta = new Vector2(cellSize - tileGap, cellSize - tileGap);
                    tile.anchoredPosition = GridToBoard(HomeLanePaths[seat, lane, 0] + 0.5f, HomeLanePaths[seat, lane, 1] + 0.5f);
                    var col = SeatColors[seat];
                    tile.GetComponent<Image>().color = new Color(col.r, col.g, col.b, 0.4f);
                    tiles.Add(tile);
                }
            }

            var center = new GameObject("Center", typeof(RectTransform), typeof(Image)).GetComponent<RectTransform>();
            center.SetParent(boardRoot, false);
            center.sizeDelta = new Vector2(cellSize * 3f, cellSize * 3f);
            center.anchoredPosition = GridToBoard(7.5f, 7.5f);
            center.GetComponent<Image>().color = new Color(0.15f, 0.15f, 0.2f, 0.9f);
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
                return HomeLanePosition(piece.seat, piece.progress) + TokenOffset(pieceIndex) * 0.4f;
            }

            if (piece.state == "finished")
            {
                return FinishedPosition(piece.seat, pieceIndex);
            }

            return TrackPosition(piece.trackIndex) + TokenOffset(pieceIndex);
        }

        private Vector2 GridToBoard(float gridX, float gridY)
        {
            var cellSize = boardSize.x / 15f;
            return new Vector2(gridX * cellSize - boardSize.x / 2f, boardSize.y / 2f - gridY * cellSize);
        }

        private Vector2 TrackPosition(int trackIndex)
        {
            var idx = Mathf.Clamp(trackIndex, 0, GridPath.GetLength(0) - 1);
            return GridToBoard(GridPath[idx, 0] + 0.5f, GridPath[idx, 1] + 0.5f);
        }

        private Vector2 YardPosition(int seat, int pieceIndex)
        {
            var s = Mathf.Clamp(seat, 0, 3);
            var p = pieceIndex % 4;
            return GridToBoard(BaseCorners[s, 0] + YardSlots[p, 0], BaseCorners[s, 1] + YardSlots[p, 1]);
        }

        private Vector2 HomeLanePosition(int seat, int progress)
        {
            var s = Mathf.Clamp(seat, 0, 3);
            var lane = Mathf.Clamp(progress - 52, 0, HomeLanePaths.GetLength(1) - 1);
            return GridToBoard(HomeLanePaths[s, lane, 0] + 0.5f, HomeLanePaths[s, lane, 1] + 0.5f);
        }

        private Vector2 FinishedPosition(int seat, int pieceIndex)
        {
            return GridToBoard(7.5f, 7.5f) + TokenOffset(pieceIndex);
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
