using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Grass : MonoBehaviour
{
    [SerializeField] private Mesh instanceMesh;
    [SerializeField] private Material instanceMaterial;
    [SerializeField] private int instanceCount = 10;
    //Can use this to calculate the size and rotation of the mesh
    [SerializeField] private ComputeShader computeShader;
    private int kernel;
    private ComputeBuffer argsBuffer;
    private const int ARGS_STRIDE = sizeof(uint) * 5;
    private ComputeBuffer positionBuffer;
    private const int POSITION_STRIDE = sizeof(float) * 4;

    private void OnEnable()
    {
        argsBuffer = new ComputeBuffer(1, ARGS_STRIDE, ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(new uint[] { 0, 1, 0, 0, 0 });
        positionBuffer = new ComputeBuffer(instanceCount, POSITION_STRIDE);
        kernel = computeShader.FindKernel("CSMain");
    }
}
