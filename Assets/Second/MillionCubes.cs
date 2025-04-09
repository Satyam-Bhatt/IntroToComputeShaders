using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MillionCubes : MonoBehaviour
{
    [SerializeField] private Mesh instanceMesh;
    [SerializeField] private Material instanceMaterial;

    private ComputeBuffer argsBuffer;
    private const int ARGS_STRIDE = sizeof(uint) * 4;

    private ComputeBuffer positionBuffer;
    private const int POSITION_STRIDE = sizeof(float) * 4;

    private void OnEnable()
    {
        argsBuffer = new ComputeBuffer(1, ARGS_STRIDE, ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(new int[] { 0, 1, 0, 0 });

        positionBuffer = new ComputeBuffer(1, POSITION_STRIDE);
        positionBuffer.SetData(new float[] { 0, 0, 0, 0 });
    }

    private void OnDisable()
    {
        argsBuffer.Release();
        positionBuffer.Release();
    }


    // Start is called before the first frame update
    void Start()
    {
        UpdateBuffers();
    }

    // Update is called once per frame
    void Update()
    {
        // What does this bounds do???
        Graphics.DrawMeshInstancedIndirect(instanceMesh, 0, instanceMaterial, new Bounds(Vector3.zero, Vector3.one * 1000), argsBuffer);
    }

    void UpdateBuffers()
    {
        uint[] _args = { 0, 1, 0, 0 };
        _args[0] = instanceMesh.GetIndexCount(0);
        _args[1] = 1;
        _args[2] = instanceMesh.GetIndexStart(0);
        _args[3] = instanceMesh.GetBaseVertex(0);

        argsBuffer.SetData(_args);

        Vector4[] _positions = { new Vector4(0, 0, 0, 0) };
        positionBuffer.SetData(_positions);
    }
}
