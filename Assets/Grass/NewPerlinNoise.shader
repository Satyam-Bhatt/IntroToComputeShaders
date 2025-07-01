Shader "Unlit/NewPerlinNoise"
{
    // https://www.shadertoy.com/view/NlSGDz
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SmoothOne ("Smoothness 1", Range(0,1)) = 0.03
        _SmoothTwo ("Smoothness 2", Range(0,1)) = 0.035
        _First ("First", Vector) = (0.075, 0.9, 0, 0)
        _Third ("Third", Vector) = (0.035, 0.1, 0, 0)
        _BottomColor("Bottom Color", Color) = (0, 0, 0, 1)
        _TopColor("Top Color", Color) = (0, 0, 0, 1)
        _BendFactor("Bend Factor", Float) = 0
        _BendScale("Bend Scale", Float) = 0
        _BendScaleX("Bend Scale X", Float) = 0
        _Angle("Angle", Float) = 0
        _BlendAngleScale("Blend Angle Scale", Float) = 0
        _NoiseScale ("Noise Scale", Float) = 1.0
        _NoiseSpeed ("Noise Speed", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            vec2 gradientDirection(uint hash) {
                switch (int(hash) & 3) { // look at the last two bits to pick a gradient direction
                case 0:
                    return vec2(1.0, 1.0);
                case 1:
                    return vec2(-1.0, 1.0);
                case 2:
                    return vec2(1.0, -1.0);
                case 3:
                    return vec2(-1.0, -1.0);
                }
            }

            vec2 fade(vec2 t) {
                // 6t^5 - 15t^4 + 10t^3
	            return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
            }

            uint hash(uvec2 x, uint seed){
                const uint m = 0x5bd1e995U;
                uint hash = seed;
                // process first vector element
                uint k = x.x; 
                k *= m;
                k ^= k >> 24;
                k *= m;
                hash *= m;
                hash ^= k;
                // process second vector element
                k = x.y; 
                k *= m;
                k ^= k >> 24;
                k *= m;
                hash *= m;
                hash ^= k;
	            // some final mixing
                hash ^= hash >> 13;
                hash *= m;
                hash ^= hash >> 15;
                return hash;
            }

            float perlinNoise(vec2 position, uint seed) {
                vec2 floorPosition = floor(position);
                vec2 fractPosition = position - floorPosition;
                uvec2 cellCoordinates = uvec2(floorPosition);
                float value1 = dot(gradientDirection(hash(cellCoordinates, seed)), fractPosition);
                float value2 = dot(gradientDirection(hash((cellCoordinates + uvec2(1, 0)), seed)), fractPosition - vec2(1.0, 0.0));
                float value3 = dot(gradientDirection(hash((cellCoordinates + uvec2(0, 1)), seed)), fractPosition - vec2(0.0, 1.0));
                float value4 = dot(gradientDirection(hash((cellCoordinates + uvec2(1, 1)), seed)), fractPosition - vec2(1.0, 1.0));
                return interpolate(value1, value2, value3, value4, fade(fractPosition));
            }


            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                floar4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
