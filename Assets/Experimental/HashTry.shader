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
                // then XOR it with the original value (the ^ symbol)
                // 0 XOR 0 = 0
                // 0 XOR 1 = 1  
                // 1 XOR 0 = 1
                // 1 XOR 1 = 0
                // This spreads out the bits and introduces non-linearity - small changes in input create larger changes in the 
                // bit pattern. [AVALANCHE EFFECT]
                // The U at the end of the integer means that the value is unsigned integer.
                // This avoid issues with compiler behavour
                // -> Overflow behaviour - What to do when the value exceeds the range of the data type.
                // -> Bit operations
				n = (n << 13U) ^ n;
                // n*n*n just create the AVALANCHE EFFECT as defined above
                // 0x789221U  Hexadecimal for 7,902,753
                // 0x1376312589U Hexadecimal for 5,265,502,601
                // All three numbers are Magic numbers. They ensure that the values are spread out evenly (choosen through testing)
                // 15731U is a prime number so would avoid creating cycle and creates a good bit mixing when used in multiplication
                // 0x789221U and 0x1376312589U are choosen out of testing
                // This follows a common hash pattern: ax^3 + bx^2 + cx + d where a,b,c, and d are magic constants
                // Cubic polynomial = AVALANCHE EFFECT
				n = n * (n * n * 15731U + 0x789221U) + 0x1376312589U;
                // This normalizes the value between 0 and 1
                // We cast to float as we need a floating value between 0 and 1
                // 0x7fffffff is the largest 31 bit positive integer
                // it has its sign bit set to 0 and other bit set to 1 = 01111111111111111111111111111111 [IMAGE FROM CLAUDE]
                // n & 0x7fffffffU the & operator in between just makes the value of n positive and also modifies is [IMAGE FROM CLAUDE]
                // but it keeps the remaining bits the same
                // it is also qucker than using the abs function
                // then we divide by 0x7fffffff to get the value between 0 and 1
                // if we fivide it by 0xffffffff then the final value would be less than 1 as we are removing the first bit when we
                // do the & operation.
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
                // Make sure its unisgned integer. We don't need floating values as we are creating squares
                // multiplying the uv just increases the range from 0 to 1 to 0 to multiplication factor
                uint2 uv = i.uv * 10;

                // If we just hash y or x values (straight values) [IMAGE]
                //float hashVal = hash(uv.y);
                // If we hash x + y values (diagonal values) [IMAGE]
				//float hashVal = hash(uv.x + uv.y);
                // if we hash x * offset + y (true randomness) [IMAGE]
				float hashVal = hash(uv.x * 10000 + uv.y);

                // We can use these if we want to make stripe pattern [IMAGE]
                float2 uv2 = i.uv;
				//float hashVal = hash(uv2.x * 10 + uv2.y * 10);

                return hashVal;
            }
            ENDCG
        }
    }
}
