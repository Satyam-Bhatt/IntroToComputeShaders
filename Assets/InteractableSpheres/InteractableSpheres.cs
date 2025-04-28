using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InteractableSpheres : MonoBehaviour
{
    // Mesh that we will instance can be sphere, square etc
    [SerializeField] private Mesh instanceMesh;
    // Material for the mesh. It determines how the mesh will be rendered. The position and color are set in here(somewhat only mostly done in compute shader)
    [SerializeField] private Material instanceMaterial;
    // The count of instances
    [SerializeField] private int count = 0;
    // Compute shader which manipulates the position of the instances. This controls the push and pull of the instances
    [SerializeField] private ComputeShader computeShader;
    // Id of the kernel in the compute shader. There can be many kernels in the compute shader so we should know which we want to dispatch
    private int kernel;
    // Buffer that stores the arguments for the indirect draw call. Basically it tells how to render the mesh with the instances
    private ComputeBuffer argsBuffer;
    // Stride for the argsBuffer. argsBuffer has 5 uints so stride is 5*sizeof(uint). Basically the GPU needs to jump this bytes much to get to the 
    // information for the next instance
    private const int ARGS_STRIDE = sizeof(uint) * 5;

    private ComputeBuffer positionBuffer;
    private const int POSITION_STRIDE = sizeof(float) * 4;

    private ComputeBuffer originalPositionBuffer;

    [SerializeField] private Transform mover;

    // Start is called before the first frame update
    void OnEnable()
    {
        argsBuffer = new ComputeBuffer(1, ARGS_STRIDE, ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(new int[] { 0, 1, 0, 0, 0 });

        positionBuffer = new ComputeBuffer(count, POSITION_STRIDE);

        originalPositionBuffer = new ComputeBuffer(count, POSITION_STRIDE);

        kernel = computeShader.FindKernel("CSMain");
    }

    private void OnDisable()
    {
        argsBuffer.Release();
        argsBuffer = null;

        positionBuffer.Release();
        positionBuffer = null;

        originalPositionBuffer.Release();
        originalPositionBuffer = null;
    }

    private void Start()
    {
        UpdateBuffer();
    }

    // Update is called once per frame
    void Update()
    {
        computeShader.SetVector("position", mover.position);
        computeShader.Dispatch(kernel, Mathf.CeilToInt(count / 128.0f), 1, 1);

        Graphics.DrawMeshInstancedIndirect(instanceMesh, 0, instanceMaterial, new Bounds(Vector3.zero, Vector3.one * 1000), argsBuffer);
    }

    void UpdateBuffer()
    {
        uint[] _args = { 0, 1, 0, 0, 0 };
        _args[0] = instanceMesh.GetIndexCount(0);
        _args[1] = (uint)count;
        _args[2] = instanceMesh.GetIndexStart(0);
        _args[3] = instanceMesh.GetBaseVertex(0);
        _args[4] = 0; // Instance Start

        argsBuffer.SetData(_args);

        Vector4[] _positions = new Vector4[count];

        // Calculate dimensions for a cube grid
        int dimension = Mathf.CeilToInt(Mathf.Pow(count, 1.0f / 3.0f));
        float spacing = 1.5f; // Distance between cube centers

        // Calculate the starting offset to center the grid
        float offset = -spacing * (dimension - 1) / 2.0f;

        for (int i = 0; i < count; i++)
        {
            // Convert 1D index to 3D coordinates
            int x = i % dimension;
            int y = (i / dimension) % dimension;
            int z = i / (dimension * dimension);

            // Position with equal spacing and centered around origin
            float posX = offset + x * spacing;
            float posY = offset + y * spacing;
            float posZ = offset + z * spacing;

            _positions[i] = new Vector4(posX, posY, posZ, 0);
        }

        positionBuffer.SetData(_positions);
        originalPositionBuffer.SetData(_positions);

        computeShader.SetBuffer(kernel, "Result", positionBuffer);
        computeShader.SetBuffer(kernel, "OriginalPosition", originalPositionBuffer);

        instanceMaterial.SetBuffer("position", positionBuffer);
        instanceMaterial.SetBuffer("originalPosition", originalPositionBuffer);
    }
}
