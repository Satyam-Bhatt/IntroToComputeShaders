Shader "Unlit/NewPerlinNoise"
{
    // https://www.shadertoy.com/view/NlSGDz
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scale ("Scale", Float) = 0.0625
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

            uint hash(uint2 x, uint seed){
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

            float2 gradientDirection(uint hash) {
                switch (int(hash) & 3) { // look at the last two bits to pick a gradient direction
                case 0:
                    return float2(1.0, 1.0);
                case 1:
                    return float2(-1.0, 1.0);
                case 2:
                    return float2(1.0, -1.0);
                case 3:
                    return float2(-1.0, -1.0);
                }
            }

            float interpolate(float value1, float value2, float value3, float value4, float2 t) {
                return lerp(lerp(value1, value2, t.x), lerp(value3, value4, t.x), t.y);
            }

            float2 fade(float2 t) {
                // 6t^5 - 15t^4 + 10t^3
	            return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
            }

            float perlinNoise(float2 position, uint seed) {
                float2 floorPosition = floor(position);
                float2 fractPosition = position - floorPosition;
                uint2 cellCoordinates = uint2(floorPosition);
                float value1 = dot(gradientDirection(hash(cellCoordinates, seed)), fractPosition);
                float value2 = dot(gradientDirection(hash((cellCoordinates + uint2(1, 0)), seed)), fractPosition - float2(1.0, 0.0));
                float value3 = dot(gradientDirection(hash((cellCoordinates + uint2(0, 1)), seed)), fractPosition - float2(0.0, 1.0));
                float value4 = dot(gradientDirection(hash((cellCoordinates + uint2(1, 1)), seed)), fractPosition - float2(1.0, 1.0));
                return interpolate(value1, value2, value3, value4, fade(fractPosition));
            }

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Scale;

            StructuredBuffer<float4x4> transform;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            // Used it to visualize perlin noise as per the position in the transform buffer
            float4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv * 16;
                float2 uv_ID = floor(uv);
                //return float4(uv/16, 0, 1);

                // ID is 
				uint id = 16 * floor(uv_ID.y) + floor(uv_ID.x);
                float4x4 m = transform[id];
                float3 _position = float3(m._m03, m._m13, m._m23);
                //return float4(_position.x/16, _position.z/16, 0, 1);

                uint seed = 0x578437adU;
                //float value = perlinNoise(uv + _Time.y, seed);
                float value = perlinNoise(float2(_position.x, _position.z) * _Scale + _Time.y, seed); // 1/16 = 0.0625
                value = (value + 1.0) * 0.5;
                return value;
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
