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
}
