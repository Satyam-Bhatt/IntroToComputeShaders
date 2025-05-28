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

            // The value changes after we get value with increment of 1. Like when the input parameter has values between 0 and 1 then
            // we will get the same color but when the value increased and goes from 0 to 2 then we will get one same color/value for
            // values between 0 and 1 and one different color/value for values between 1 and 2. So as the values increases the color
			// changes randomly but the color remains the same between 2 whole numbers.
            // 1 to 2 will be same color, 2 to 3 will be same color, 3 to 4 will be same color and so on.
            // 1.5 will give the same color as 1.8 but 2.2 will give a different color as 1.8 [IMAGE]
            // So as the n value gets higher and higher we see randomness but with square patter or line patttern depends on the value [IMAGE]
            // The resulting values are always between 0 and 1
            float hash(uint n) { // How does this work
				// integer hash copied from Hugo Elias
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
