Shader "Unlit/ShellTextureMesh"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Index ("Index", Int) = 0
        _Count ("Count", Int) = 1
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
                float3 normals : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            float hash(uint n) { // How does this work
				// integer hash copied from Hugo Elias
				n = (n << 13U) ^ n;
				n = n * (n * n * 15731U + 0x789221U) + 0x1376312589U;
				return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
			}

            sampler2D _MainTex;
            float4 _MainTex_ST;
            int _Index;
            int _Count;

            v2f vert (appdata v)
            {
                v2f o;

                float height = (float)_Index/(float)_Count; // Important conversion

                v.vertex.xyz = v.vertex.xyz + v.normals * height;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float height = (float)_Index/(float)_Count; // Important conversion

                uint2 tid = i.uv * 100;
                uint seed = tid.x * 1031 + tid.y;

                float4 outCol = float4(0,1,0,1);
                float rand = hash(seed);

                if(rand < height)
                {
                    discard;
                    //outCol = float4(0,0,0,0);
                }

				return outCol * height;

            }
            ENDCG
        }
    }
}
