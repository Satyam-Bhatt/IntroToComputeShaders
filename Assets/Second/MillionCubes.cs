using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MillionCubes : MonoBehaviour
{
    [SerializeField] private Mesh instanceMesh;
    [SerializeField] private Material instanceMaterial;
    [SerializeField] private int count = 0;

    private ComputeBuffer argsBuffer;
    private const int ARGS_STRIDE = sizeof(uint) * 5;

    private ComputeBuffer positionBuffer;
    private const int POSITION_STRIDE = sizeof(float) * 4;

    private ComputeBuffer positionUpdate;
    private const int POSITION_UPDATE_STRIDE = sizeof(float) * 4;

    [SerializeField] private Transform position_Mover;

    private void OnEnable()
    {
        argsBuffer = new ComputeBuffer(1, ARGS_STRIDE, ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(new int[] { 0, 1, 0, 0, 0 });

        positionBuffer = new ComputeBuffer(count, POSITION_STRIDE);
        //positionBuffer.SetData(new float[] { 0, 0, 0, 0 });

        positionUpdate = new ComputeBuffer(1, POSITION_UPDATE_STRIDE, ComputeBufferType.Structured, ComputeBufferMode.Dynamic);
        positionUpdate.SetData(new float[] { 0, 0, 0, 0 });
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
        //Graphics.DrawMeshInstancedIndirect(instanceMesh, 0, instanceMaterial, new Bounds(Vector3.zero, Vector3.one * 1000), argsBuffer);
        Graphics.DrawMeshInstancedIndirect(instanceMesh, 0, instanceMaterial, new Bounds(Vector3.zero, Vector3.one * 1000), argsBuffer);

        if(Input.GetKey(KeyCode.S))
        {
            position_Mover.Translate(new Vector3(0, 0, 10f ) * Time.deltaTime);
        }
        if(Input.GetKey(KeyCode.W))
        {
            position_Mover.Translate(new Vector3(0, 0, -10f ) * Time.deltaTime);
        }
        if(Input.GetKey(KeyCode.A))
        {
            position_Mover.Translate(new Vector3(-10f , 0, 0) * Time.deltaTime);
        }
        if(Input.GetKey(KeyCode.D))
        {
            position_Mover.Translate(new Vector3(10f , 0, 0) * Time.deltaTime);
        }
        if(Input.GetKey(KeyCode.Q))
        {
            position_Mover.Translate(new Vector3(0, 10f , 0) * Time.deltaTime);
        }
        if(Input.GetKey(KeyCode.E))
        {
            position_Mover.Translate(new Vector3(0, -10f , 0) * Time.deltaTime);
        }

        positionUpdate.SetData(new float[] { position_Mover.position.x, position_Mover.position.y, position_Mover.position.z, 0 });
        instanceMaterial.SetBuffer("positionUpdate", positionUpdate);

    }

    void UpdateBuffers()
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

        instanceMaterial.SetBuffer("position", positionBuffer);

    }
}
