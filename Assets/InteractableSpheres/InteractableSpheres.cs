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

    // Buffer that stores the positions of the instances
    private ComputeBuffer positionBuffer;
    // As each position is 4 floats, stride is 4*sizeof(float)
    private const int POSITION_STRIDE = sizeof(float) * 4;

    // Buffer that stores the original positions of the instances. We create a seperate buffer for this because if we use the position buffer then the
    // values would change whenever we update the position buffer as both the buffer would point to the same area in the GPU memory
    private ComputeBuffer originalPositionBuffer;

    // The object that we are moving and that pushes the things away
    [SerializeField] private Transform mover;

    // Used to initialize the buffers
    void OnEnable()
    {
        // Initialize the args buffer. Args buffer has a seperate buffer type as it is an argument used by the GPU/Method we are using
        argsBuffer = new ComputeBuffer(1, ARGS_STRIDE, ComputeBufferType.IndirectArguments);
        // Initialize the args buffer with some default values
        argsBuffer.SetData(new int[] { 0, 1, 0, 0, 0 });

        // Initialize the position buffer with the amount of squares we want to render
        positionBuffer = new ComputeBuffer(count, POSITION_STRIDE);

        // Initialize the original position buffer with the amount of squares we want to render. We use this buffer to get the object 
        // back to their original position
        originalPositionBuffer = new ComputeBuffer(count, POSITION_STRIDE);

        // Find the kernel in the compute shader so that we can dispatch it
        kernel = computeShader.FindKernel("CSMain");
    }
     // Releases the buffers so that they are no longer occupied and can be used by some other program
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
        // Every frame we update the position of the object that is pushing things away in the compute shader 
        computeShader.SetVector("position", mover.position);
        // Dispatch the compute shader as per the numthreads. As we have 128 , 1 , 1 number of threads we divide the count by 128
        // so that we just dont go over the number of threads and the count starts from 0 every time
        computeShader.Dispatch(kernel, Mathf.CeilToInt(count / 128.0f), 1, 1);

        // Send the GPU instructions to render the instances with the arguments
        Graphics.DrawMeshInstancedIndirect(instanceMesh, 0, instanceMaterial, new Bounds(Vector3.zero, Vector3.one * 1000), argsBuffer);
    }

    // Fill the buffers and set appropriate values
    void UpdateBuffer()
    {
        // Set actual values for the args buffer
        uint[] _args = { 0, 1, 0, 0, 0 };
        // Number of indices in the mesh. A cube has 36 indices(6 faces * 2 triangles per face * 3 vertices per triangle). Indices just avoid repating 
        // vertices as triangles share vertices
        _args[0] = instanceMesh.GetIndexCount(0); 
        _args[1] = (uint)count; // Number of instances we want to render
        _args[2] = instanceMesh.GetIndexStart(0); // Indicates the index to start from. 
        // Basically if the model has many submeshes we pack all the vertices of all the submeshes in a single vertex buffer. This argument just defines
        // the offset we need to add so that the GPU knows where to start rendering from for different sub meshes. It is 0 for a single submesh model || Claude ||
        _args[3] = instanceMesh.GetBaseVertex(0); 
        _args[4] = 0; // Instance Start typically 0

        argsBuffer.SetData(_args); // Upload the data to the GPU

        Vector4[] _positions = new Vector4[count];

        // Calculate dimensions for a cube grid
        int dimension = Mathf.CeilToInt(Mathf.Pow(count, 1.0f / 3.0f));
        float spacing = 1.5f; // Distance between cube centers

        // Calculate the starting offset to center the grid
        float offset = -spacing * (dimension - 1) / 2.0f;

        // i = z * dimension * dimension + y * dimension + x || Refer to One Note ||
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

        positionBuffer.SetData(_positions); // Upload data to the GPU
        originalPositionBuffer.SetData(_positions); // Upload data to the GPU

        // Set the values in the compute buffer. Setting the pointer in the compute shader to point towards the buffer that we created earlier in the 
        // OnEnable method
        computeShader.SetBuffer(kernel, "Result", positionBuffer); 
        computeShader.SetBuffer(kernel, "OriginalPosition", originalPositionBuffer);

        // Set the values in the instance material. 
        instanceMaterial.SetBuffer("position", positionBuffer); // This buffer is used to position the verticies of the mesh in the world
        // This buffer is used to calculate the distance from the original position to the new position and then color the objects appropriately
        instanceMaterial.SetBuffer("originalPosition", originalPositionBuffer); 

        // In the above 4 lines we are setting the pointer of each variable that we have in the shader and the compute shader to the buffer we have created
        // in the GPU
    }
}
