using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SampleCompute : MonoBehaviour
{
    public ComputeShader cs;
    public RenderTexture result;

    // Start is called before the first frame update
    void Start()
    {
        int kernel = cs.FindKernel("CSMain");

        result = new RenderTexture(512, 512, 24);
        result.enableRandomWrite = true;
        result.Create();
        cs.SetTexture(kernel, "Result", result);
        cs.Dispatch(kernel, 512/128, 512/1, 1);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
