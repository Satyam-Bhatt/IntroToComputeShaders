using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InteractableSpheres : MonoBehaviour
{
    [SerializeField] private Mesh instanceMesh;
    [SerializeField] private Material instanceMaterial;
    [SerializeField] private int count = 0;
    [SerializeField] private ComputeShader computeShader;

    private int kernel;

    private ComputeBuffer argsBuffer;
    private const int ARGS_STRIDE = sizeof(uint) * 5;

    private ComputeBuffer positionBuffer;
    private const int POSITION_STRIDE = sizeof(float) * 4;

    [SerializeField] private Transform mover;

    // Start is called before the first frame update
    void OnEnable()
    {
        argsBuffer = new ComputeBuffer(1, ARGS_STRIDE, ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(new int[] { 0, 1, 0, 0, 0 });

        positionBuffer = new ComputeBuffer(count, POSITION_STRIDE);

        kernel = computeShader.FindKernel("CSMain");
    }

    private void OnDisable()
    {
        argsBuffer.Release();
        argsBuffer = null;

        positionBuffer.Release();
        positionBuffer = null;
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 dir = new Vector3(Input.GetAxis("Horizontal"), 0, Input.GetAxis("Vertical"));
        mover.Translate(dir * Time.deltaTime * 20);
    }
}
