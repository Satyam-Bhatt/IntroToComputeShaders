using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ProceduralPyramidRenderer : MonoBehaviour
{
    [Tooltip("A mesh to extrude the pyramids from")]
    [SerializeField] private Mesh sourceMesh = default;
    [Tooltip("The pyramid geometry creating compute shader")]
    [SerializeField] private ComputeShader pyramidComputeShader = default;
    [Tooltip("The material to render the pyramid mesh")]
    [SerializeField] private Material material = default;
    [Tooltip("Whether the pyramid should cast shadows")]
    [SerializeField] private float pyramidHeight = 1.0f;
    [Tooltip("Whether the pyramid should cast shadews")]
    [SerializeField] private float animationFrequency = 1.0f;

    // The structure to send to the compute shader
    // This layout kind assures that the data is laid out sequentially
    [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    private struct SourceVertex
    {
        public Vector3 position;
        public Vector2 uv;
    }

    // A state variable to help keep track of whether compute buffers have been set up
    private bool initialiezed;
    // A compute buffer to hold vertex data of the source mesh
    private ComputeBuffer sourceVertBuffer;
    // A compute buffer to hold index data of the source mesh
    private ComputeBuffer sourceTriBuffer;
    // A compute buffer to hold vertex data of the generated mesh
    private ComputeBuffer drawBuffer;
    // A compute buffer to hold indirect draw arguments
    private int idPyramidKernel;
    // The id of the kernel in the tri to vert count compute shader
    private int dispatchSize;

    // The size of one entry into the various compute buffers
    private const int SOURCE_VERT_STRIDE = sizeof(float) * (3 + 2);
    private const int SOURCE_TRI_STRIDE = sizeof(int);
    private const int DRAW_STRIDE = sizeof(float) * (3 + (3 + 2) * 3);

    private void OnEnable()
    {
        // If initialized, call on disable to clean things up
        if(initialiezed)
        {
            OnDisable();
        }
        initialiezed = true;

        // Grab data from the source mesh
        Vector3[] positions = sourceMesh.vertices;
        Vector2[] uvs = sourceMesh.uv;
        int[] tris = sourceMesh.triangles;

        // Create the data to upload to the source vert buffer
        SourceVertex[] vertices = new SourceVertex[positions.Length];
        for (int i = 0; i < vertices.Length; i++)
        {
            vertices[i] = new SourceVertex()
            {
                position = positions[i],
                uv = uvs[i]
            };
        }
        int numTriangles = tris.Length / 3; // The number of triangles in the source mesh is the index array / 3

        // Create compute buffers
        // The stride is the size, in bytes, each object in the buffer takes up
        sourceVertBuffer = new ComputeBuffer(vertices.Length, SOURCE_VERT_STRIDE, ComputeBufferType.Structured, ComputeBufferMode.Immutable);
        sourceVertBuffer.SetData(vertices);
        sourceTriBuffer = new ComputeBuffer(tris.Length, SOURCE_TRI_STRIDE, ComputeBufferType.Structured, ComputeBufferMode.Immutable);
        sourceTriBuffer.SetData(tris);
        // We split each triangle into three new ones
        drawBuffer = new ComputeBuffer(numTriangles * 3, DRAW_STRIDE, ComputeBufferType.Append);
        drawBuffer.SetCounterValue(0); // Set the count to zero

        // Cache the kernel IDs we will be dispatching
        idPyramidKernel = pyramidComputeShader.FindKernel("CSMain");

        // Set data on the shaders
        pyramidComputeShader.SetBuffer(idPyramidKernel, "_SourceVertices", sourceVertBuffer);
        pyramidComputeShader.SetBuffer(idPyramidKernel, "_SourceTriangles", sourceTriBuffer);
        pyramidComputeShader.SetBuffer(idPyramidKernel, "_DrawTriangles", drawBuffer);
        pyramidComputeShader.SetInt("_NumSourceTriangles", numTriangles);

        material.SetBuffer("_DrawTriangles", drawBuffer);

        // Calculate the number of threads to use. Get the thread size from the kernel
        // Then, divide the number of triangles by that size
        pyramidComputeShader.GetKernelThreadGroupSizes(idPyramidKernel, out uint threadGroupSize, out _, out _);
        dispatchSize = Mathf.CeilToInt((float)numTriangles / threadGroupSize);
    }

    private void OnDisable()
    {
        
    }
}
