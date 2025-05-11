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
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"
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
            float _HeightUp;

            v2f vert (appdata v)
            {
                v2f o;

                float height = (float)_Index/(float)_Count; // Important conversion
                // Look at the x^a graph in desmos
                // At the start when the value is very very low we increase the height and then we flatten the curve. 
                // This ensures that when the culling of pixels is higher(when height increases) the spheres are closer so that they look dense
                // This adds volume to the strands when Index is high and the strands are a closer when the height increases
                height = pow (height, 0.1); 

                v.vertex.xyz = v.vertex.xyz + v.normals * height;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float height = (float)_Index/(float)_Count; // Important conversion

                uint2 tid = i.uv * 500;
                float2 fracUV = frac(i.uv * 500) * 2 - 1;
                float dist = length(fracUV);
                uint seed = tid.x * 100031 + tid.y;

                float4 outCol = float4(0,1,0,1);
                float rand = hash(seed);

                // Gives square shape
                // if(rand < height)
                // {
                //     discard;
                //     //outCol = float4(0,0,0,0);
                // }

                // For the strands to look pointy
                if(dist > 1 * (rand - height))
				{
					discard;
					//outCol = float4(0,0,0,0);
				}

                // Light
                float light = DotClamped(i.normal, _WorldSpaceLightPos0)  * 0.5f + 0.5f;
                light = pow(light, 1);

                float ambientOcclusion = pow(height, 1.3);

				//ambientOcclusion += _OcclusionBias;

				ambientOcclusion = saturate(ambientOcclusion);

				return outCol * ambientOcclusion * light;
				//return outCol * height * light;


            }
            ENDCG
        }
    }
}
