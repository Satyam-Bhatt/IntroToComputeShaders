Shader "Unlit/ElipseSDF"
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

            // Plotting equation of elipse directly to get gradient but its not SDF_Circle
            // Its just gives if the point is inside then the value is less than 1
            // If the point is outside then the value is greater than 1
            // If the point is on the elipse then the value is 1
            // This is because the equation of elipse is x^2/a^2 + y^2/b^2 = 1
            float SDF_Elipse(float2 p)
            {
                float a = 5;
                float b = 3;

                float dist = p.x * p.x / (a * a ) + p.y * p.y / (b * b) ;
                // if (dist > 1.0)
                // {
                //     dist = dist - 1.0;
                // }
                return 1-dist;
            }

            // Plotting equation of circle
            // x^2 + y^2 = r^2
            // if the point is inside the circle then the value is less than the radius
            // if the point is outside the circle then the value is greater than the radius
			// if the point is on the circle then the value is equal to the radius
            float SDF_Circle(float2 p)
            {
				float2 c = float2(1, 0);
				float r = 5;
				float dist = p.x * p.x + p.y * p.y;
                // we dividing by r*r to get the value between 0 and 1
				return 1 - dist / (r * r);
            }

            float SDF_Circle2(float2 p)
            {
				//float2 c = float2(0, 0);
				float r = 4;
				float dist = length(p) - r;
				return 1 - dist;
            }

            float opSmoothUnion(float d1, float d2, float k)
            {
                float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
                return lerp(d2, d1, h) - k * h * (1.0 - h);
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
                float2 uv = i.uv * 2 - 1;
                uv = uv * 6;
				float dist = SDF_Elipse(uv);
                //return float4(dist, dist, dist, 1);
                float dist2 = SDF_Circle2(uv);
                return float4(dist2, dist2, dist2, 1);
               
            }
            ENDCG
        }
    }
}
