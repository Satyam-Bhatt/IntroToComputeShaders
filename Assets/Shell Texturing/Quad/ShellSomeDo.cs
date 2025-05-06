using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShellSomeDo : MonoBehaviour
{
    public GameObject planeToInstantiate;
    public int numShells = 10;
    public float heightStep = 0.05f;  // Controls spacing between shells

    void Start()
    {
        // Get the original material to create instances from
        Material originalMaterial = planeToInstantiate.GetComponent<MeshRenderer>().sharedMaterial;

        for (int i = 0; i < numShells; i++)
        {
            // Instantiate the plane
            GameObject current = Instantiate(planeToInstantiate);
            current.transform.position = new Vector3(0, i * heightStep, 0);

            // Create a unique material instance for this shell
            Material instanceMaterial = new Material(originalMaterial);

            // Set the shader properties with proper names (_Index, _Count)
            instanceMaterial.SetInt("_Index", i);
            instanceMaterial.SetInt("_Count", numShells);

            // Apply the material to this instance
            current.GetComponent<MeshRenderer>().material = instanceMaterial;
        }
    }
}
