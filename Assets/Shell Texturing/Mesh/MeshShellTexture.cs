using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MeshShellTexture : MonoBehaviour
{
    public GameObject meshToDuplicate;
    public int numShells = 16;
    public float heightStep = 0.1f;

    private void Start()
    {
        for(int i = 0; i < numShells; i++)
        {
            GameObject newMesh = Instantiate(meshToDuplicate, transform);
            newMesh.transform.localPosition = new Vector3(0, 0, 0);
        }
    }
}
