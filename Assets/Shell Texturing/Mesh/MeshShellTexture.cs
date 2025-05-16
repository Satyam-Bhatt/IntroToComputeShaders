using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MeshShellTexture : MonoBehaviour
{
    public GameObject meshToDuplicate;
    public int numShells = 16;
    public float heightStep = 0.1f;
    public float speed = 10f;

    private Vector3 direction;
    private Vector3 displacementDirection;
    [SerializeField] private Material papaMaterial;

    private void Start()
    {
        Material originalMat = meshToDuplicate.GetComponent<MeshRenderer>().sharedMaterial;
        for(int i = 0; i < numShells; i++)
        {
            GameObject newMesh = Instantiate(meshToDuplicate, transform);
            newMesh.transform.localPosition = new Vector3(0, 0, 0);
            Material newMat = new Material(originalMat);
            newMat.SetInt("_Index", i);
            newMat.SetInt("_Count", numShells);
            newMesh.GetComponent<MeshRenderer>().material = newMat;
        }
    }

    private void Update()
    {
        if(Input.GetKey(KeyCode.UpArrow))
        {
            direction = new Vector3(0, 1 * speed * Time.deltaTime, 0);
            transform.Translate(0,1 * speed * Time.deltaTime,0);
        }
        else if(Input.GetKey(KeyCode.DownArrow))
        {
            direction = new Vector3(0, -1 * speed * Time.deltaTime, 0);
            transform.Translate(0,-1 * speed * Time.deltaTime,0);
        }
        else if(Input.GetKey(KeyCode.LeftArrow))
        {
            direction = new Vector3(-1 * speed * Time.deltaTime,0,0);
            transform.Translate(-1 * speed * Time.deltaTime,0,0);
        }
        else if(Input.GetKey(KeyCode.RightArrow))
        {
            direction = new Vector3(1 * speed * Time.deltaTime,0,0);
            transform.Translate(1 * speed * Time.deltaTime,0,0);
        }

        direction.Normalize();
        
        // Hair displacement
        displacementDirection -= direction * speed * Time.deltaTime;
        if(direction == Vector3.zero) 
            displacementDirection.y -= speed * Time.deltaTime;

        if (displacementDirection.magnitude > 1) displacementDirection.Normalize();

        Shader.SetGlobalVector("_Displacement", displacementDirection);
    }
}
