using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace LudoRush.Game
{
    public sealed class LudoBoardPresenter : MonoBehaviour
    {
        [SerializeField] private RectTransform boardRoot;
        [SerializeField] private Vector2 boardSize = new Vector2(930f, 930f);
        [SerializeField] private float tokenSize = 44f;

        private readonly Dictionary<string, RectTransform> tokens = new Dictionary<string, RectTransform>();
        private readonly Dictionary<string, RectTransform> moveHints = new Dictionary<string, RectTransform>();
        private readonly List<GameObject> boardVisuals = new List<GameObject>();

        private Action<string> pieceTapped;
        private bool darkMode = true;
        private LudoRoomSnapshot latestSnapshot;

        private static readonly Color[] SeatColors =
        {
            Color32(255, 48, 57),
            Color32(32, 134, 232),
            Color32(255, 209, 42),
            Color32(39, 184, 75)
        };

        private static readonly Color[] SeatSoftColors =
        {
            Color32(255, 127, 127),
            Color32(126, 176, 248),
            Color32(255, 230, 126),
            Color32(105, 226, 147)
        };

        private static readonly int[,] TrackCells =
        {
            {6,14},{6,13},{6,12},{6,11},{6,10},{6,9},{5,8},{4,8},{3,8},{2,8},{1,8},{0,8},{0,7},
            {0,6},{1,6},{2,6},{3,6},{4,6},{5,6},{6,5},{6,4},{6,3},{6,2},{6,1},{6,0},{7,0},
            {8,0},{8,1},{8,2},{8,3},{8,4},{8,5},{9,6},{10,6},{11,6},{12,6},{13,6},{14,6},{14,7},
            {14,8},{13,8},{12,8},{11,8},{10,8},{9,8},{8,9},{8,10},{8,11},{8,12},{8,13},{8,14},{7,14}
        };

        private static readonly int[,,] HomeLaneCells =
        {
            {{7,13},{7,12},{7,11},{7,10},{7,9}},
            {{1,7},{2,7},{3,7},{4,7},{5,7}},
            {{7,1},{7,2},{7,3},{7,4},{7,5}},
            {{13,7},{12,7},{11,7},{10,7},{9,7}}
        };

        private static readonly int[,] BaseCorners = {{0, 9}, {0, 0}, {9, 0}, {9, 9}};
        private static readonly float[,] YardSlots = {{2.1f, 2.1f}, {3.9f, 2.1f}, {2.1f, 3.9f}, {3.9f, 3.9f}};
        private static readonly int[] SafeTrackIndexes = {0, 8, 13, 21, 26, 34, 39, 47};

        public RectTransform BoardRoot => boardRoot;

        public void AttachTo(RectTransform parent)
        {
            EnsureBoardRoot();
            boardRoot.SetParent(parent, false);
            boardRoot.anchorMin = new Vector2(0.5f, 0.5f);
            boardRoot.anchorMax = new Vector2(0.5f, 0.5f);
            boardRoot.pivot = new Vector2(0.5f, 0.5f);
            boardRoot.anchoredPosition = Vector2.zero;
            boardRoot.sizeDelta = boardSize;
            ShowEmptyBoard();
        }

        public void SetDarkMode(bool enabled)
        {
            if (darkMode == enabled && boardVisuals.Count > 0)
            {
                return;
            }

            darkMode = enabled;
            RebuildBoard();
            if (latestSnapshot != null)
            {
                ApplySnapshot(latestSnapshot);
            }
        }

        public void SetPieceTapped(Action<string> handler)
        {
            pieceTapped = handler;
        }

        public void ShowEmptyBoard()
        {
            EnsureBoardRoot();
            if (boardVisuals.Count == 0)
            {
                RebuildBoard();
            }
        }

        public void ApplySnapshot(LudoRoomSnapshot snapshot)
        {
            latestSnapshot = snapshot;
            ShowEmptyBoard();

            var activeMoves = new HashSet<string>();
            if (snapshot?.availableMoves != null)
            {
                foreach (var move in snapshot.availableMoves)
                {
                    if (!string.IsNullOrWhiteSpace(move))
                    {
                        activeMoves.Add(move);
                    }
                }
            }

            UpdateMoveHints(snapshot, activeMoves);

            if (snapshot?.pieces == null)
            {
                return;
            }

            foreach (var piece in snapshot.pieces)
            {
                if (piece == null)
                {
                    continue;
                }

                var token = GetOrCreateToken(piece);
                token.anchoredPosition = PositionForPiece(piece);
                token.SetAsLastSibling();
            }
        }

        private void EnsureBoardRoot()
        {
            if (boardRoot != null)
            {
                return;
            }

            boardRoot = transform as RectTransform;
            if (boardRoot == null)
            {
                boardRoot = new GameObject("LudoBoard", typeof(RectTransform)).GetComponent<RectTransform>();
            }
        }

        private void RebuildBoard()
        {
            EnsureBoardRoot();

            for (var i = boardRoot.childCount - 1; i >= 0; i--)
            {
                Destroy(boardRoot.GetChild(i).gameObject);
            }

            boardVisuals.Clear();
            tokens.Clear();
            moveHints.Clear();

            boardRoot.sizeDelta = boardSize;
            boardRoot.gameObject.SetActive(true);

            CreateBoardBase();
            CreateHomeZones();
            CreateTrackCells();
            CreateHomeLanes();
            CreateCenter();
        }

        private void CreateBoardBase()
        {
            var baseRect = CreateRect("BoardBase", boardRoot, Vector2.zero, boardSize, darkMode ? Color32(35, 16, 47) : Color32(255, 249, 221));
            baseRect.SetAsFirstSibling();
            var shadow = baseRect.gameObject.AddComponent<Shadow>();
            shadow.effectColor = new Color(0f, 0f, 0f, darkMode ? 0.6f : 0.22f);
            shadow.effectDistance = new Vector2(0f, -10f);
            var outline = baseRect.gameObject.AddComponent<Outline>();
            outline.effectColor = Color32(255, 212, 38);
            outline.effectDistance = new Vector2(4f, -4f);
        }

        private void CreateHomeZones()
        {
            for (var seat = 0; seat < 4; seat++)
            {
                var x = BaseCorners[seat, 0] + 3f;
                var y = BaseCorners[seat, 1] + 3f;
                var zone = CreateGridRect($"HomeZone_{seat}", x, y, 6f, 6f, SeatColors[seat], 0.88f);
                AddOutline(zone, new Color(1f, 1f, 1f, 0.78f), 3f);

                var tray = CreateGridRect($"HomeTray_{seat}", x, y, 3.7f, 3.7f, darkMode ? Color32(40, 8, 52) : Color.white, 0.94f);
                AddOutline(tray, darkMode ? new Color(1f, 1f, 1f, 0.36f) : new Color(0.49f, 0.30f, 1f, 0.42f), 2f);
            }
        }

        private void CreateTrackCells()
        {
            for (var i = 0; i < TrackCells.GetLength(0); i++)
            {
                var color = IsStartIndex(i) ? SeatSoftColors[StartSeatForIndex(i)] : (darkMode ? Color32(251, 246, 224) : Color.white);
                var tile = CreateGridRect($"Track_{i}", TrackCells[i, 0] + 0.5f, TrackCells[i, 1] + 0.5f, 0.92f, 0.92f, color, 1f);
                AddOutline(tile, darkMode ? Color32(31, 36, 56) : Color32(215, 200, 255), 1.35f);

                if (IsSafeIndex(i))
                {
                    var star = CreateText(tile, "*", 34, Color32(255, 212, 38), TextAnchor.MiddleCenter);
                    star.fontStyle = FontStyle.Bold;
                }
            }
        }

        private void CreateHomeLanes()
        {
            for (var seat = 0; seat < HomeLaneCells.GetLength(0); seat++)
            {
                for (var lane = 0; lane < HomeLaneCells.GetLength(1); lane++)
                {
                    var tile = CreateGridRect($"HomeLane_{seat}_{lane}",
                        HomeLaneCells[seat, lane, 0] + 0.5f,
                        HomeLaneCells[seat, lane, 1] + 0.5f,
                        0.92f,
                        0.92f,
                        SeatSoftColors[seat],
                        0.88f);
                    AddOutline(tile, Color.white, 1.2f);
                }
            }
        }

        private void CreateCenter()
        {
            CreateGridRect("CenterRed", 7f, 8f, 1.9f, 1.9f, SeatColors[0], 1f);
            CreateGridRect("CenterBlue", 7f, 7f, 1.9f, 1.9f, SeatColors[1], 1f);
            CreateGridRect("CenterYellow", 8f, 7f, 1.9f, 1.9f, SeatColors[2], 1f);
            CreateGridRect("CenterGreen", 8f, 8f, 1.9f, 1.9f, SeatColors[3], 1f);
            var cap = CreateGridRect("CenterCap", 7.5f, 7.5f, 1.15f, 1.15f, darkMode ? Color32(255, 246, 214) : Color.white, 0.98f);
            AddOutline(cap, Color32(255, 212, 38), 2f);
        }

        private RectTransform GetOrCreateToken(LudoPiece piece)
        {
            if (tokens.TryGetValue(piece.pieceId, out var existing))
            {
                return existing;
            }

            var token = new GameObject(piece.pieceId, typeof(RectTransform), typeof(RushCircleGraphic), typeof(Button)).GetComponent<RectTransform>();
            token.SetParent(boardRoot, false);
            token.sizeDelta = new Vector2(tokenSize, tokenSize);
            token.GetComponent<RushCircleGraphic>().color = SeatColors[Mathf.Clamp(piece.seat, 0, SeatColors.Length - 1)];
            AddOutline(token, Color.white, 3f);

            var button = token.GetComponent<Button>();
            button.transition = Selectable.Transition.ColorTint;
            button.onClick.AddListener(() => pieceTapped?.Invoke(piece.pieceId));

            var shine = new GameObject("Shine", typeof(RectTransform), typeof(RushCircleGraphic)).GetComponent<RectTransform>();
            shine.SetParent(token, false);
            shine.anchorMin = new Vector2(0.18f, 0.54f);
            shine.anchorMax = new Vector2(0.48f, 0.84f);
            shine.offsetMin = Vector2.zero;
            shine.offsetMax = Vector2.zero;
            shine.GetComponent<RushCircleGraphic>().color = new Color(1f, 1f, 1f, 0.78f);

            tokens[piece.pieceId] = token;
            return token;
        }

        private void UpdateMoveHints(LudoRoomSnapshot snapshot, HashSet<string> activeMoves)
        {
            foreach (var hint in moveHints)
            {
                hint.Value.gameObject.SetActive(false);
            }

            if (snapshot?.pieces == null || activeMoves.Count == 0)
            {
                return;
            }

            foreach (var piece in snapshot.pieces)
            {
                if (piece == null || !activeMoves.Contains(piece.pieceId))
                {
                    continue;
                }

                if (!moveHints.TryGetValue(piece.pieceId, out var hint))
                {
                    hint = new GameObject($"Hint_{piece.pieceId}", typeof(RectTransform), typeof(RushCircleGraphic)).GetComponent<RectTransform>();
                    hint.SetParent(boardRoot, false);
                    hint.sizeDelta = new Vector2(tokenSize * 1.72f, tokenSize * 1.72f);
                    var graphic = hint.GetComponent<RushCircleGraphic>();
                    graphic.innerRadius = 0.70f;
                    graphic.color = Color32(255, 212, 38);
                    moveHints[piece.pieceId] = hint;
                }

                hint.gameObject.SetActive(true);
                hint.anchoredPosition = PositionForPiece(piece);
            }
        }

        private Vector2 PositionForPiece(LudoPiece piece)
        {
            var pieceIndex = PieceIndex(piece.pieceId);

            if (piece.state == "yard" || piece.progress < 0)
            {
                return YardPosition(piece.seat, pieceIndex);
            }

            if (piece.state == "home")
            {
                return HomeLanePosition(piece.seat, piece.progress) + TokenOffset(pieceIndex) * 0.38f;
            }

            if (piece.state == "finished")
            {
                return GridToBoard(7.5f, 7.5f) + TokenOffset(pieceIndex) * 0.5f;
            }

            return TrackPosition(piece.trackIndex) + TokenOffset(pieceIndex);
        }

        private RectTransform CreateGridRect(string name, float gridX, float gridY, float gridW, float gridH, Color color, float alpha)
        {
            color.a *= alpha;
            var cell = boardSize.x / 15f;
            var pos = GridToBoard(gridX, gridY);
            var size = new Vector2(cell * gridW, cell * gridH);
            return CreateRect(name, boardRoot, pos, size, color);
        }

        private RectTransform CreateRect(string name, Transform parent, Vector2 anchoredPosition, Vector2 size, Color color)
        {
            var rect = new GameObject(name, typeof(RectTransform), typeof(Image)).GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = anchoredPosition;
            rect.sizeDelta = size;
            rect.GetComponent<Image>().color = color;
            boardVisuals.Add(rect.gameObject);
            return rect;
        }

        private Text CreateText(RectTransform parent, string value, int size, Color color, TextAnchor anchor)
        {
            var rect = new GameObject("Label", typeof(RectTransform), typeof(Text)).GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;

            var text = rect.GetComponent<Text>();
            text.text = value;
            text.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
            text.fontSize = size;
            text.fontStyle = FontStyle.Bold;
            text.color = color;
            text.alignment = anchor;
            return text;
        }

        private static void AddOutline(RectTransform rect, Color color, float distance)
        {
            var outline = rect.gameObject.AddComponent<Outline>();
            outline.effectColor = color;
            outline.effectDistance = new Vector2(distance, -distance);
        }

        private Vector2 GridToBoard(float gridX, float gridY)
        {
            var cell = boardSize.x / 15f;
            return new Vector2(gridX * cell - boardSize.x / 2f, boardSize.y / 2f - gridY * cell);
        }

        private Vector2 TrackPosition(int trackIndex)
        {
            var idx = Mathf.Clamp(trackIndex, 0, TrackCells.GetLength(0) - 1);
            return GridToBoard(TrackCells[idx, 0] + 0.5f, TrackCells[idx, 1] + 0.5f);
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
            var lane = Mathf.Clamp(progress - 52, 0, HomeLaneCells.GetLength(1) - 1);
            return GridToBoard(HomeLaneCells[s, lane, 0] + 0.5f, HomeLaneCells[s, lane, 1] + 0.5f);
        }

        private Vector2 TokenOffset(int pieceIndex)
        {
            return pieceIndex switch
            {
                0 => new Vector2(-9f, -9f),
                1 => new Vector2(9f, -9f),
                2 => new Vector2(-9f, 9f),
                _ => new Vector2(9f, 9f)
            };
        }

        private static int PieceIndex(string pieceId)
        {
            if (string.IsNullOrWhiteSpace(pieceId))
            {
                return 0;
            }

            var index = pieceId.LastIndexOf('p');
            if (index < 0 || index == pieceId.Length - 1)
            {
                return 0;
            }

            return int.TryParse(pieceId.Substring(index + 1), out var value) ? value : 0;
        }

        private static bool IsStartIndex(int index)
        {
            return index == 0 || index == 13 || index == 26 || index == 39;
        }

        private static int StartSeatForIndex(int index)
        {
            if (index == 0)
            {
                return 0;
            }

            if (index == 13)
            {
                return 1;
            }

            if (index == 26)
            {
                return 2;
            }

            return 3;
        }

        private static bool IsSafeIndex(int index)
        {
            for (var i = 0; i < SafeTrackIndexes.Length; i++)
            {
                if (SafeTrackIndexes[i] == index)
                {
                    return true;
                }
            }

            return false;
        }

        private static Color Color32(byte r, byte g, byte b)
        {
            return new Color32(r, g, b, 255);
        }
    }
}
