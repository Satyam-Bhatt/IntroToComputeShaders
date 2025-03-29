using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class test : MonoBehaviour
{
    public Mesh sourceMesh;

    // Start is called before the first frame update
    void Start()
    {
        Debug.Log(sourceMesh.triangles.Length);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
