using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Grass : MonoBehaviour
{
    [SerializeField] private Mesh instanceMesh;
    [SerializeField] private Material instanceMaterial;
    [SerializeField] private int instanceCount = 500000;
    [SerializeField] private ComputeShader computeShader;

    // Chunking parameters
    [SerializeField] private int maxChunkSize = 65536; // Max instances per chunk
    [SerializeField] private bool useChunkedDispatch = true;
    [SerializeField] private int framesPerChunk = 1; // How many frames to spread chunk processing across

    private int kernel;
    private ComputeBuffer argsBuffer;
    private const int ARGS_STRIDE = sizeof(uint) * 5;
    private ComputeBuffer positionBuffer;
    private const int POSITION_STRIDE = sizeof(float) * 4;
    private ComputeBuffer transformBuffer;
    private const int TRANSFORM_STRIDE = sizeof(float) * 16;
    private ComputeBuffer noiseBuffer;
    private const int NOISE_STRIDE = sizeof(float);

    // Chunking variables
    private int currentChunkIndex = 0;
    private List<ChunkData> chunks = new List<ChunkData>();
    private int frameCounter = 0;

    [SerializeField] private Material testMat;

    [System.Serializable]
    public struct ChunkData
    {
        public int startIndex;
        public int count;
        public int dispatchX;
        public int dispatchY;
        public int dispatchZ;
    }

    private void OnEnable()
    {
        argsBuffer = new ComputeBuffer(1, ARGS_STRIDE, ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(new uint[] { 0, 1, 0, 0, 0 });

        positionBuffer = new ComputeBuffer(instanceCount, POSITION_STRIDE);
        transformBuffer = new ComputeBuffer(instanceCount, TRANSFORM_STRIDE);
        noiseBuffer = new ComputeBuffer(instanceCount, NOISE_STRIDE);

        kernel = computeShader.FindKernel("CSMain");
        if (kernel < 0)
        {
            Debug.LogError("Could not find kernel 'CSMain' in compute shader!");
            return;
        }

        SetupChunks();
    }

    private void OnDisable()
    {
        argsBuffer?.Release();
        argsBuffer = null;
        positionBuffer?.Release();
        positionBuffer = null;
        transformBuffer?.Release();
        transformBuffer = null;
        noiseBuffer?.Release();
        noiseBuffer = null;
    }

    private void Start()
    {
        UpdateBuffer();
    }

    private void Update()
    {
        // Update chunks over multiple frames if enabled
        if (useChunkedDispatch && framesPerChunk > 1)
        {
            Debug.Log($"Processing chunk {currentChunkIndex} of {chunks.Count}");
            UpdateChunkedBuffer();
        }

        Graphics.DrawMeshInstancedIndirect(instanceMesh, 0, instanceMaterial,
            new Bounds(Vector3.zero, Vector3.one * 1000), argsBuffer);
    }

    private void SetupChunks()
    {
        chunks.Clear();

        if (!useChunkedDispatch || instanceCount <= maxChunkSize)
        {
            // Single chunk
            chunks.Add(new ChunkData
            {
                startIndex = 0,
                count = instanceCount,
                dispatchX = CalculateDispatchX(instanceCount),
                dispatchY = CalculateDispatchY(instanceCount),
                dispatchZ = 1
            });
        }
        else
        {
            // Multiple chunks
            for (int i = 0; i < instanceCount; i += maxChunkSize)
            {
                int chunkCount = Mathf.Min(maxChunkSize, instanceCount - i);
                chunks.Add(new ChunkData
                {
                    startIndex = i,
                    count = chunkCount,
                    dispatchX = CalculateDispatchX(chunkCount),
                    dispatchY = CalculateDispatchY(chunkCount),
                    dispatchZ = 1
                });
            }
        }

        Debug.Log($"Created {chunks.Count} chunks for {instanceCount} instances");
    }

    private int CalculateDispatchX(int count)
    {
        // Your shader uses [numthreads(8, 8, 1)] and calculates positions in a grid
        // We need to calculate how many thread groups we need
        int perAxis = Mathf.CeilToInt(Mathf.Sqrt(count));
        return Mathf.CeilToInt(perAxis / 8.0f);
    }

    private int CalculateDispatchY(int count)
    {
        int perAxis = Mathf.CeilToInt(Mathf.Sqrt(count));
        return Mathf.CeilToInt(perAxis / 8.0f);
    }

    private void UpdateBuffer()
    {
        // Initialize buffers
        InitializeBuffers();

        if (useChunkedDispatch)
        {
            // Process all chunks at once (for immediate update)
            ProcessAllChunks();
        }
        else
        {
            // Original single dispatch
            DispatchSingleChunk(0, instanceCount);
        }

        UpdateArgsBuffer();
    }

    private void UpdateChunkedBuffer()
    {
        frameCounter++;

        if (frameCounter >= framesPerChunk)
        {
            frameCounter = 0;

            if (chunks.Count > 0)
            {
                ProcessChunk(currentChunkIndex);
                currentChunkIndex = (currentChunkIndex + 1) % chunks.Count;
            }
        }
    }

    private void InitializeBuffers()
    {
        // Initialize transform buffer with identity matrices
        Matrix4x4[] transforms = new Matrix4x4[instanceCount];
        float[] noise = new float[instanceCount];

        for (int i = 0; i < instanceCount; i++)
        {
            transforms[i] = Matrix4x4.TRS(Vector3.zero, Quaternion.identity, Vector3.one);
            noise[i] = 0.0f;
        }

        transformBuffer.SetData(transforms);
        noiseBuffer.SetData(noise);

        // Set buffers to compute shader
        computeShader.SetBuffer(kernel, "Result", transformBuffer);
        computeShader.SetBuffer(kernel, "noise", noiseBuffer);

        // Set buffers to material
        instanceMaterial.SetBuffer("transform", transformBuffer);
        instanceMaterial.SetBuffer("noise", noiseBuffer);
    }

    private void ProcessAllChunks()
    {
        for (int i = 0; i < chunks.Count; i++)
        {
            ProcessChunk(i);
        }
    }

    private void ProcessChunk(int chunkIndex)
    {
        if (chunkIndex >= chunks.Count) return;

        ChunkData chunk = chunks[chunkIndex];

        // Set compute shader parameters for this chunk
        computeShader.SetInt("count", chunk.count);
        computeShader.SetInt("chunkOffset", chunk.startIndex);
        computeShader.SetInt("totalCount", instanceCount);
        computeShader.SetFloat("dispatchX", chunk.dispatchX);
        computeShader.SetFloat("dispatchY", chunk.dispatchY);

        // Dispatch the chunk
        computeShader.Dispatch(kernel, chunk.dispatchX, chunk.dispatchY, chunk.dispatchZ);
    }

    private void DispatchSingleChunk(int startIndex, int count)
    {
        int dispatchX = CalculateDispatchX(count);
        int dispatchY = CalculateDispatchY(count);

        computeShader.SetInt("count", count);
        computeShader.SetFloat("dispatchX", dispatchX);
        computeShader.SetFloat("dispatchY", dispatchY);

        computeShader.Dispatch(kernel, dispatchX, dispatchY, 1);
    }

    private void UpdateArgsBuffer()
    {
        uint[] args = { 0, 1, 0, 0, 0 };
        args[0] = (uint)instanceMesh.GetIndexCount(0);
        args[1] = (uint)instanceCount;
        args[2] = instanceMesh.GetIndexStart(0);
        args[3] = instanceMesh.GetBaseVertex(0);
        args[4] = 0;
        argsBuffer.SetData(args);
    }

    // Additional method to force update all chunks immediately
    [ContextMenu("Force Update All Chunks")]
    public void ForceUpdateAllChunks()
    {
        ProcessAllChunks();
    }

    // Method to change chunk size at runtime
    public void SetChunkSize(int newChunkSize)
    {
        maxChunkSize = newChunkSize;
        SetupChunks();
    }

    // Method to toggle chunked dispatch
    public void SetChunkedDispatch(bool enabled)
    {
        useChunkedDispatch = enabled;
        SetupChunks();
    }
}