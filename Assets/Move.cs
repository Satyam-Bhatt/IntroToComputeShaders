using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Move : MonoBehaviour
{
    public Transform cubePosition;
    public ComputeShader moveComputeShader;
    public float offset = 1f;

    private ComputeBuffer moveBuffer;
    private int idToKernel;

    private const int STRIDE = 3 * sizeof(float);

    private void OnEnable()
    {
        moveBuffer = new ComputeBuffer(1, STRIDE, ComputeBufferType.Structured, ComputeBufferMode.Dynamic);
        idToKernel = moveComputeShader.FindKernel("CSMain");
        moveComputeShader.SetBuffer(idToKernel, "Result", moveBuffer);
    }
}
