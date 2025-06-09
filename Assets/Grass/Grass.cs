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
        Matrix4x4 check = new Matrix4x4();
        check.m00 = 1;
        check.m01 = 2;
        check.m02 = 3;
        check.m03 = 4;
        check.m10 = 5;
        check.m11 = 6;
        check.m12 = 7;
        check.m13 = 8;
        check.m20 = 9;
        check.m21 = 10;
        check.m22 = 11;
        check.m23 = 12;
        check.m30 = 13;
        check.m31 = 14;
        check.m32 = 15;
        check.m33 = 16;
        Debug.Log(check);
        Debug.Log($"Row 0: {check.GetRow(0)}");
        Debug.Log($"Row 1: {check.GetRow(1)}");
        Debug.Log($"Row 2: {check.GetRow(2)}");
        Debug.Log($"Row 3: {check.GetRow(3)}");

        //Transform Buffer
        Matrix4x4[] transforms = new Matrix4x4[instanceCount];
        for (int i = 0; i < instanceCount; i++)
        {
            transforms[i] = Matrix4x4.TRS(new Vector3(1,1,1), Quaternion.identity, Vector3.one);
            Debug.Log(transforms[i]);
        }
        //transformBuffer.SetData(transforms);
        //instanceMaterial.SetBuffer("transform", transformBuffer);

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
