Shader "Unlit/ShellTextureMesh"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Index ("Index", Int) = 0
        _Count ("Count", Int) = 1
        _Thickness ("Thickness", Float) = 10.0
        _StrandDensity ("StrandDensity", Float) = 0.6
		_StrandCurve ("StrandCurve", Float) = 1.0
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

            float random (float2 uv)
            {
                return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123);


                // If you want the strands to vary in size in realtime
                // return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123 * _Time.y * 0.00001); 

            }

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float3 _Displacement;

            int _Index;
            int _Count;
            float _StrandDensity;
            float _StrandCurve;
            float _Thickness = 10.0;
            float _Density = 1000;
            float _LightPower = 4.0;
            float _AmbientOcclusionPower = 1.0;
            float _AmbientOcclusionUplift = 0.1;
            bool _AmbientOcclusion = true;
            float4 _Color = float4(0.1, 0.1, 0.1, 1.0);

            v2f vert (appdata v)
            {
                v2f o;

                float height = (float)_Index/(float)_Count; // Important conversion
                // Look at the x^a (a is greater than 0 and less than 1) graph in desmos 
                // At the start when the value is very very low we increase the height and then we flatten the curve. 
                // This ensures that when the culling of pixels is higher(when height increases) the spheres are closer so that they look dense
                // This adds volume to the strands when Index is high and the strands are a closer when the height increases
                height = pow (height, _StrandDensity); 

                v.vertex.xyz = v.vertex.xyz + v.normals * height;

                float curve = pow(height, _StrandCurve);
                v.vertex.xyz = v.vertex.xyz + _Displacement * 0.7 * curve;

                o.vertex = UnityObjectToClipPos(v.vertex);

                // Since we are preparing to send data over to the fragment shader, we finalize the normal by converting it to world space
				// and it will be interpolated across triangles in the fragment shader, you kinda don't really need to worry about this since it just works (tm)
                o.normal = normalize(UnityObjectToWorldNormal(v.normals));

                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float height = (float)_Index/(float)_Count; // Important conversion 

                // This defines how big each Square is in the mesh. More the number we multiply there will be more squares hence more strands
                // but thinner strands in the same surface area. 
                uint2 tid = i.uv * _Density;
                // Multiplication value should be same as the above one 
                float2 fracUV = frac(i.uv * _Density) * 2 - 1;
                float dist = length(fracUV); // Makes the strands circular
                uint randomisationValue = _Density * 10 + 10; // This should be greater than the density so the pattern doesn't repeat
                uint seed = tid.x * randomisationValue + tid.y;

                float4 outCol = _Color;

                // My Technique. Use it to have strands that increase in decrease in length by multiplying with time in the random function
                float2 myUV = i.uv * 1000;
                myUV = floor(myUV);
                float myRand = random(myUV);// + _Time.y * 0.0005); // Or add this to change the length of strand
                //////

                float rand = hash(seed);
                rand = myRand;

                // Gives square shape
                // if(rand < height)
                // {
                //     discard;
                //     //outCol = float4(0,0,0,0);
                // }

                // For the strands to look pointy
                if(dist > _Thickness * (rand - height) && _Index > 0) // Thickness is here also ensures no pixels are discarded in the first mesh
				{
					discard;
					//outCol = float4(0,0,0,0);
				}

                // Light
                float light = DotClamped(i.normal.xyz, _WorldSpaceLightPos0.xyz)  * 0.5f + 0.5f;
                light = pow(light, _LightPower);

                float ambientOcclusion = pow(height, _AmbientOcclusionPower);

				ambientOcclusion += _AmbientOcclusionUplift;

				ambientOcclusion = saturate(ambientOcclusion);

                if(!_AmbientOcclusion)
                    // For fur look
				    return float4( light * outCol.xyz ,1);
                else
                    // For different Light and thorny look
				    return float4( light * outCol.xyz * ambientOcclusion ,1);

				//return outCol * height * light;


            }
            ENDCG
        }
    }
}
