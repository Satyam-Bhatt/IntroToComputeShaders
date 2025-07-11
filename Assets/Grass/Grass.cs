using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

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

    private ComputeBuffer noiseBuffer;
    private const int NOISE_STRIDE = sizeof(float);

    private int dispatchX, dispatchY, dispatchZ;

    [SerializeField] private Material testMat;

    private void OnEnable()
    {
        argsBuffer = new ComputeBuffer(1, ARGS_STRIDE, ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(new uint[] { 0, 1, 0, 0, 0 });
        positionBuffer = new ComputeBuffer(instanceCount, POSITION_STRIDE);
        kernel = computeShader.FindKernel("CSMain");
        if (kernel < 0)
        {
            Debug.LogError("Could not find kernel 'CSMain' in compute shader!");
            return;
        }

        transformBuffer = new ComputeBuffer(instanceCount, TRANSFORM_STRIDE);
        noiseBuffer = new ComputeBuffer(instanceCount, NOISE_STRIDE);
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
        //CheckNormals();
        UpdateBuffer();
    }

    private void CheckNormals()
    {
        Vector3[] normals = instanceMesh.normals;
        for (int i = 0; i < normals.Length; i++)
        {
            if (normals[i].x < 0)
            {
                normals[i] = new Vector3(normals[i].x * -1, normals[i].y, normals[i].z);
            }
            Debug.Log(normals[i]);
        }

        instanceMesh.normals = normals;
    }

    private void Update()
    {

        Graphics.DrawMeshInstancedIndirect(instanceMesh, 0, instanceMaterial, new Bounds(Vector3.zero, Vector3.one * 1000), argsBuffer);
    }

    private void UpdateBuffer()
    {
        // Noise Buffer
        float[] noise = new float[instanceCount];
        //Transform Buffer
        Matrix4x4[] transforms = new Matrix4x4[instanceCount];
        for (int i = 0; i < instanceCount; i++)
        {
            transforms[i] = Matrix4x4.TRS(new Vector3(i,1,i), Quaternion.identity, Vector3.one);
            noise[i] = 0.0f;
        }
        transformBuffer.SetData(transforms);
        noiseBuffer.SetData(noise);

        computeShader.SetBuffer(kernel, "Result", transformBuffer);
        instanceMaterial.SetBuffer("transform", transformBuffer);
        computeShader.SetBuffer(kernel, "noise", noiseBuffer);
        instanceMaterial.SetBuffer("noise", noiseBuffer);

        uint[] _args = {0 , 1, 0, 0, 0 };
        _args[0] = (uint)instanceMesh.GetIndexCount(0);
        _args[1] = (uint)instanceCount;
        _args[2] = instanceMesh.GetIndexStart(0);
        _args[3] = instanceMesh.GetBaseVertex(0);
        _args[4] = 0;

        argsBuffer.SetData(_args);

        dispatchX = Mathf.CeilToInt(instanceCount / 8.0f);
        dispatchY = Mathf.CeilToInt(instanceCount / 8.0f);
        dispatchZ = 1;

        computeShader.SetFloat("dispatchX", dispatchX);
        computeShader.SetFloat("dispatchY", dispatchY);
        computeShader.SetInt("count", instanceCount);
        // Dispatch in Update shaders if we are updating the buffer every frame
        computeShader.Dispatch(kernel, dispatchX, dispatchY, dispatchZ);

        //testMat.SetBuffer("transform", transformBuffer);


    }
}
