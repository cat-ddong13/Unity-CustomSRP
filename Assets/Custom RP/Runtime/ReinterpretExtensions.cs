using System.Runtime.InteropServices;

namespace Rendering.CustomSRP.Runtime
{
    public static class ReinterpretExtensions
    {
        // 调整为显式
        [StructLayout(LayoutKind.Explicit)]
        private struct IntFloat
        {
            // 使两者在内存布局中重叠（即指向同一块内存）

            [FieldOffset(0)] public int intValue;
            [FieldOffset(0)] public float floatValue;
        }

        /// <summary>
        /// int 转 float
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public static float ReinterpreaAsFloat(this int value)
        {
            IntFloat converter = default;
            converter.intValue = value;
            return converter.floatValue;
        }
    }
}