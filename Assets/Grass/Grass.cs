using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Grass : MonoBehaviour
{
    [SerializeField] private Mesh instanceMesh;
    [SerializeField] private Material instanceMaterial;
    [SerializeField] private int instanceCount = 16;
    //Can use this to calculate the size and rotation of the mesh
    [SerializeField] private ComputeShader computeShader;
    private int kernel;
    private ComputeBuffer argsBuffer;
    private const int ARGS_STRIDE = sizeof(uint) * 5;
    private ComputeBuffer positionBuffer;
    private const int POSITION_STRIDE = sizeof(float) * 4;
    
    private ComputeBuffer transformBuffer;
    private const int TRANSFORM_STRIDE = sizeof(float) * 16;

    private void OnEnable()
    {
        argsBuffer = new ComputeBuffer(1, ARGS_STRIDE, ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(new uint[] { 0, 1, 0, 0, 0 });
        positionBuffer = new ComputeBuffer(instanceCount, POSITION_STRIDE);
        kernel = computeShader.FindKernel("CSMain");

        transformBuffer = new ComputeBuffer(instanceCount, TRANSFORM_STRIDE);
    }

    private void OnDisable()
    {
        argsBuffer.Release();
        argsBuffer = null;

        positionBuffer.Release();
        positionBuffer = null;
    }

    private void Start()
    {
        UpdateBuffer();
    }

    private void Update()
    {
        Graphics.DrawMeshInstancedIndirect(instanceMesh, 0, instanceMaterial, new Bounds(Vector3.zero, Vector3.one * 1000), argsBuffer);
    }

    private void UpdateBuffer()
    {
        //Transform Buffer
        Matrix4x4[] transforms = new Matrix4x4[instanceCount];
        for (int i = 0; i < instanceCount; i++)
        {
            transforms[i] = Matrix4x4.TRS(new Vector3(1,1,1), Quaternion.identity, Vector3.one);
            Debug.Log(transforms[i]);
        }
        transformBuffer.SetData(transforms);
        instanceMaterial.SetBuffer("transform", transformBuffer);

        uint[] _args = {0 , 1, 0, 0, 0 };
        _args[0] = (uint)instanceMesh.GetIndexCount(0);
        _args[1] = (uint)instanceCount;
        _args[2] = instanceMesh.GetIndexStart(0);
        _args[3] = instanceMesh.GetBaseVertex(0);
        _args[4] = 0;

        argsBuffer.SetData(_args);


        Vector4[] positions = new Vector4[instanceCount];
        for (int i = 0; i < instanceCount; i++)
        {
            //positions[i] = new Vector4(Random.Range(-1f, 1f) + i, 0, Random.Range(-1f, 1f) + i, 1);
            positions[i] = new Vector4(0, 0, 0, 1);
        }
        positionBuffer.SetData(positions);

        computeShader.SetBuffer(kernel, "Result", positionBuffer);
        instanceMaterial.SetBuffer("position", positionBuffer);

        int dispatchX = Mathf.CeilToInt(instanceCount / 8.0f);
        int dispatchY = Mathf.CeilToInt(instanceCount / 8.0f);
        int dispatchZ = 1;

        computeShader.SetFloat("dispatchX", dispatchX);
        computeShader.SetFloat("dispatchY", dispatchY);

        // Dispatch in Update shaders if we are updating the buffer every frame
        computeShader.Dispatch(kernel, dispatchX, dispatchY, dispatchZ);

    }
}
