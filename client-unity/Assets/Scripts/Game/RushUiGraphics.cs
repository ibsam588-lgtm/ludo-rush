using UnityEngine;
using UnityEngine.UI;

namespace LudoRush.Game
{
    public sealed class RushGradientGraphic : MaskableGraphic
    {
        public Color topLeft = new Color(1f, 0.31f, 0.64f);
        public Color topRight = new Color(1f, 0.85f, 0.35f);
        public Color bottomLeft = new Color(0.24f, 0.85f, 1f);
        public Color bottomRight = new Color(0.48f, 0.30f, 1f);

        protected override void OnPopulateMesh(VertexHelper vh)
        {
            vh.Clear();
            var rect = GetPixelAdjustedRect();

            AddVertex(vh, rect.xMin, rect.yMin, bottomLeft);
            AddVertex(vh, rect.xMin, rect.yMax, topLeft);
            AddVertex(vh, rect.xMax, rect.yMax, topRight);
            AddVertex(vh, rect.xMax, rect.yMin, bottomRight);
            vh.AddTriangle(0, 1, 2);
            vh.AddTriangle(2, 3, 0);
        }

        private static void AddVertex(VertexHelper vh, float x, float y, Color vertexColor)
        {
            vh.AddVert(new Vector3(x, y), vertexColor, Vector2.zero);
        }
    }

    public sealed class RushCircleGraphic : MaskableGraphic
    {
        [Range(12, 96)] public int segments = 36;
        [Range(0f, 1f)] public float innerRadius = 0f;

        protected override void OnPopulateMesh(VertexHelper vh)
        {
            vh.Clear();
            var rect = GetPixelAdjustedRect();
            var radius = Mathf.Min(rect.width, rect.height) * 0.5f;
            var center = rect.center;

            if (innerRadius <= 0.001f)
            {
                vh.AddVert(center, color, Vector2.zero);
                for (var i = 0; i <= segments; i++)
                {
                    var angle = i * Mathf.PI * 2f / segments;
                    var point = center + new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * radius;
                    vh.AddVert(point, color, Vector2.zero);
                }

                for (var i = 1; i <= segments; i++)
                {
                    vh.AddTriangle(0, i, i + 1);
                }

                return;
            }

            var inner = radius * innerRadius;
            for (var i = 0; i <= segments; i++)
            {
                var angle = i * Mathf.PI * 2f / segments;
                var dir = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle));
                vh.AddVert(center + dir * radius, color, Vector2.zero);
                vh.AddVert(center + dir * inner, color, Vector2.zero);
            }

            for (var i = 0; i < segments; i++)
            {
                var outer0 = i * 2;
                var inner0 = outer0 + 1;
                var outer1 = outer0 + 2;
                var inner1 = outer0 + 3;
                vh.AddTriangle(outer0, inner0, outer1);
                vh.AddTriangle(outer1, inner0, inner1);
            }
        }
    }

    public sealed class RushDiamondGraphic : MaskableGraphic
    {
        protected override void OnPopulateMesh(VertexHelper vh)
        {
            vh.Clear();
            var rect = GetPixelAdjustedRect();
            var center = rect.center;

            vh.AddVert(new Vector3(center.x, rect.yMax), color, Vector2.zero);
            vh.AddVert(new Vector3(rect.xMax, center.y), color, Vector2.zero);
            vh.AddVert(new Vector3(center.x, rect.yMin), color, Vector2.zero);
            vh.AddVert(new Vector3(rect.xMin, center.y), color, Vector2.zero);
            vh.AddTriangle(0, 1, 2);
            vh.AddTriangle(2, 3, 0);
        }
    }
}
