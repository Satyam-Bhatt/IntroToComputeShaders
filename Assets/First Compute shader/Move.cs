using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Move : MonoBehaviour
{
    public Transform cubePosition;
    public ComputeShader moveComputeShader;
    public float offset = 1f;
    private Vector3[] positionData = new Vector3[1];

    private ComputeBuffer moveBuffer;
    private int idToKernel;

    private const int STRIDE = 3 * sizeof(float);

    private void OnEnable()
    {
        positionData[0] = transform.position;
        moveBuffer = new ComputeBuffer(1, STRIDE, ComputeBufferType.Default, ComputeBufferMode.Immutable);
        moveBuffer.SetData(positionData);
        idToKernel = moveComputeShader.FindKernel("CSMain");
        moveComputeShader.SetBuffer(idToKernel, "Result", moveBuffer);
    }

    private void OnDisable()
    {
        moveBuffer.Release();
    }

    private void LateUpdate()
    {
        moveComputeShader.SetFloat("offsetInY", offset * Mathf.Sin(Time.time * 10)/ 20);
        moveComputeShader.Dispatch(idToKernel, 1, 1, 1);

        moveBuffer.GetData(positionData);
        transform.position = positionData[0];
    }
}
