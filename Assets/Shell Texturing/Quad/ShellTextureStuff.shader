Shader "Unlit/ShellTextureStuff"
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
        Cull Off
        LOD 100

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

            float random (float2 uv)
            {
                return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123);
            }

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
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float height = (float)_Index/(float)_Count; // Important conversion

				uint2 tid = i.uv * 500;
                //uint seed = tid.x + 100 * tid.y + 100 * 10; // Why multiply with high number
                uint seed = tid.x * 1000000 + tid.y ; // Why multiply with high number. The number we multiply with tid.x should be more than 500 so that the pattern does not repeat

                float4 outColor = float4(0,1,0,1);
                float rand2 = hash(seed);
                if(rand2 > height)
				{
					rand2 = 1;
				}
                else
                {
                    discard;
                    //outColor = float4(0,0,0,1);
                    //rand2 = 0;
                }

                return outColor * height;

                // MY TECHNIQUE
                float2 myUV = i.uv * 100;
                myUV = floor(myUV);
                float myRand = random(myUV);
                
                if(myRand > height)
				{
					myRand = 1;
				}
				else
				{
                    discard;
					//myRand = 0;
				}

                return float4(0,1,0,1);

            }
            ENDCG
        }
    }
}
