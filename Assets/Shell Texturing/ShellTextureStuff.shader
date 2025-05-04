Shader "Unlit/ShellTextureStuff"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
				uint2 tid = i.uv * 100;
                //uint seed = tid.x + 100 * tid.y + 100 * 10; // Why multiply with high number
                uint seed = tid.x * 1000000 + tid.y ; // Why multiply with high number

                float rand2 = hash(seed);
                if(rand2 > 0.1)
				{
					rand2 = 1;
				}
                else
                {
                    rand2 = 0;
                }

                return rand2;

                // MY TECHNIQUE
                float2 myUV = i.uv * 100;
                myUV = floor(myUV);
                float myRand = random(myUV);
                
                if(myRand > 0.1)
				{
					myRand = 1;
				}
				else
				{
					myRand = 0;
				}

                return myRand;
            }
            ENDCG
        }
    }
}
