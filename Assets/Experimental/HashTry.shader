Shader "Unlit/HashTry"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            // ============= integer hash copied from Hugo Elias =========
            // The value changes after we get value with increment of 1. Like when the input parameter has values between 0 and 1 then
            // we will get the same color but when the value increased and goes from 0 to 2 then we will get one same color/value for
            // values between 0 and 1 and one different color/value for values between 1 and 2. So as the values increases the color
			// changes randomly but the color remains the same between 2 whole numbers.
            // 1 to 2 will be same color, 2 to 3 will be same color, 3 to 4 will be same color and so on.
            // 1.5 will give the same color as 1.8 but 2.2 will give a different color as 1.8 [IMAGE]
            // So as the n value gets higher and higher we see randomness but with square patter or line patttern depends on the value [IMAGE]
            // The resulting values are always between 0 and 1
            // The values between 0 and 1, 1 and  2, 2 and 3 are always the same because input parameter is uint so it converts all floating
            // point values to integers. We can't change it to float because we can't use bitshift operator on floating point values.
            float hash(uint n) {
				// (n << 13U) shift the bits 13 places to the left
                // then XOR it with the original value
                // 0 XOR 0 = 0
                // 0 XOR 1 = 1  
                // 1 XOR 0 = 1
                // 1 XOR 1 = 0
                // This spreads out the bits and introduces non-linearity - small changes in input create larger changes in the 
                // bit pattern. [AVALANCHE EFFECT]
				n = (n << 13U) ^ n;
				n = n * (n * n * 15731U + 0x789221U) + 0x1376312589U;
				return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
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
                float2 uv = i.uv;
                float hashVal = hash(uv.y * 2);
                return hashVal;
            }
            ENDCG
        }
    }
}
