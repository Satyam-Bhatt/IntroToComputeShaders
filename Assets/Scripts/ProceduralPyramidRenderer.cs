using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ProceduralPyramidRenderer : MonoBehaviour
{
    [Tooltip("A mesh to extrude the pyramids from")]
    [SerializeField] private Mesh sourceMesh = default;
    [Tooltip("The pyramid geometry creating compute shader")]
    [SerializeField] private ComputeShader pyramidComputeShader = default;
    [Tooltip("The triangle count adjustment compute shader")]
    [SerializeField] private ComputeShader triToVertComputeShader = default;
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
    private bool initialized;
    // A compute buffer to hold vertex data of the source mesh
    private ComputeBuffer sourceVertBuffer;
    // A compute buffer to hold index data of the source mesh
    private ComputeBuffer sourceTriBuffer;
    // A compute buffer to hold vertex data of the generated mesh
    private ComputeBuffer drawBuffer;
    // A compute buffer to hold indirect draw arguments
    private ComputeBuffer argsBuffer;
    // The id of the kernel in the pyramid compute shader
    private int idPyramidKernel;
    // The id of the kernel in the tri to ver count compute shader
    private int idTriToVertKernel;
    // The x dispatch size for the pyramid compute shader
    private int dispatchSize;
    // The local bounds of the generated mesh
    private Bounds localBounds;

    // The size of one entry into the various compute buffers
    private const int SOURCE_VERT_STRIDE = sizeof(float) * (3 + 2);
    private const int SOURCE_TRI_STRIDE = sizeof(int);
    private const int DRAW_STRIDE = sizeof(float) * (3 + (3 + 2) * 3);
    private const int ARGS_STRIDE = sizeof(int) * 4;

    private void OnEnable()
    {
        // If initialized, call on disable to clean things up
        if(initialized)
        {
            OnDisable();
        }
        initialized = true;

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

        argsBuffer = new ComputeBuffer(1, ARGS_STRIDE, ComputeBufferType.IndirectArguments);
        // The data in the args buffer corresponds to:
        // 0: vertex count per draw instance. We will only use one instance
        // 1: instance counr. One
        // 2: start vertex location if using a Graphics Buffer
        // 3: and start instance location if using a Graphics Buffer
        argsBuffer.SetData(new int[] { 0, 1, 0, 0 });

        // Cache the kernel IDs we will be dispatching
        idPyramidKernel = pyramidComputeShader.FindKernel("CSMain");
        idTriToVertKernel = triToVertComputeShader.FindKernel("Main");

        // Set data on the shaders
        pyramidComputeShader.SetBuffer(idPyramidKernel, "_SourceVertices", sourceVertBuffer);
        pyramidComputeShader.SetBuffer(idPyramidKernel, "_SourceTriangles", sourceTriBuffer);
        pyramidComputeShader.SetBuffer(idPyramidKernel, "_DrawTriangles", drawBuffer);
        pyramidComputeShader.SetInt("_NumSourceTriangles", numTriangles);

        triToVertComputeShader.SetBuffer(idTriToVertKernel, "_IndirectArgsBuffer", argsBuffer);

        material.SetBuffer("_DrawTriangles", drawBuffer);

        // Calculate the number of threads to use. Get the thread size from the kernel
        // Then, divide the number of triangles by that size
        pyramidComputeShader.GetKernelThreadGroupSizes(idPyramidKernel, out uint threadGroupSize, out _, out _);
        dispatchSize = Mathf.CeilToInt((float)numTriangles / threadGroupSize);

        // Get the bounds of the source mesh and then expand by the pyramid height
        localBounds = sourceMesh.bounds;
        localBounds.Expand(pyramidHeight);
    }

    private void OnDisable()
    {
        // Dispose of buffers
        if(initialized)
        {
            sourceVertBuffer.Release();
            sourceTriBuffer.Release();
            drawBuffer.Release();
            argsBuffer.Release();
        }
        initialized = false;
    }

    // This applies the game objects's transform to the local bounds
    // https://discussions.unity.com/t/can-39-t-convert-bounds-from-world-coordinates-to-local-coordinates/57667
    public Bounds TransformBounds(Bounds boundsOS)
    {
        var center = transform.TransformPoint(boundsOS.center);

        // transform the local extents' axes
        var extents = boundsOS.extents;
        var axisX = transform.TransformVector(extents.x, 0, 0);
        var axisY = transform.TransformVector(0, extents.y, 0);
        var axisZ = transform.TransformVector(0, 0, extents.z);

        // sum their absolute value to get the world extents
        extents.x = Mathf.Abs(axisX.x) + Mathf.Abs(axisY.x) + Mathf.Abs(axisZ.x);
        extents.y = Mathf.Abs(axisX.y) + Mathf.Abs(axisY.y) + Mathf.Abs(axisZ.y);
        extents.z = Mathf.Abs(axisX.z) + Mathf.Abs(axisY.z) + Mathf.Abs(axisZ.z);
        
        return new Bounds(center = center, extents = extents);
    }

    // LateUpdate is called after all Update calls
    private void LateUpdate()
    {
        // Clear the draw buffer of last frame's data
        drawBuffer.SetCounterValue(0);

        // Transform the bounds to world space
        Bounds bounds = TransformBounds(localBounds);

        // Update the shader with frame specific data
        pyramidComputeShader.SetMatrix("_LocalToWorld", transform.localToWorldMatrix);
        pyramidComputeShader.SetFloat("_PyramidHeight", pyramidHeight * Mathf.Sin(animationFrequency * Time.timeSinceLevelLoad));

        // Dispatch the pyramid shader. It will run on the GPU
        pyramidComputeShader.Dispatch(idPyramidKernel, dispatchSize, 1, 1);

        // Copy the count (stack size) of the draw buffer to the args buffer, at byte position zero
        // This sets the vertex count for our draw procedural indirect call
        ComputeBuffer.CopyCount(drawBuffer, argsBuffer, 0);

        // This the compute shader outputs triangles, but the graphics shader needs the number of vertices,
        // we need to multiply the vertex count by three. We'll do this on the GPU with a compute shader
        // so we don't have to transfer data back to the CPU
        triToVertComputeShader.Dispatch(idTriToVertKernel, 1, 1, 1);

        // DrawProceduralIndirect queues a draw call up for our generated mesh
        // It will receive a shadow casting pass, like normal
        Graphics.DrawProceduralIndirect(material, bounds, MeshTopology.Triangles, argsBuffer, 0, null, null, UnityEngine.Rendering.ShadowCastingMode.Off, true, gameObject.layer);
    }
}
