using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;

public class MeshShellTexture : MonoBehaviour
{
    public GameObject meshToDuplicate;


    private Vector3 direction;
    public Vector3 displacementDirection;
    [SerializeField] private Material papaMaterial;
    public List<GameObject> shells = new List<GameObject>();

    [Space(10)]
    [Header ("Tweakable Parameters")]
    public int numShells = 16;
    public float speed = 10f;
    public float _StrandDensity;
    public float _StrandCurve;
    public float _Thickness = 10.0f;
    public float _Density = 1000;
    public float _LightPower = 4.0f;
    public float _AmbientOcclusionPower = 1.0f;
    public float _AmbientOcclusionUplift = 0.1f;
    public int _AmbientOcclusion = 1;
    public Color _Color = new Vector4(0.1f, 0.1f, 0.1f, 1.0f);
 
    private void Start()
    {
        // Set new materals for each mesh with index count increasing as the shells are added
        Material originalMat = meshToDuplicate.GetComponent<MeshRenderer>().sharedMaterial;
        for(int i = 0; i < numShells; i++)
        {
            GameObject newMesh = Instantiate(meshToDuplicate, transform);
            shells.Add(newMesh);
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
        else
        {
            direction = Vector3.zero;
        }

        direction.Normalize();
        
        // Hair displacement
        // Move the displacement vector towards the opposite direction of movement
        displacementDirection -= direction * speed * Time.deltaTime;
        // If there is no input, move the displacement vector down slowly
        if(direction == Vector3.zero) 
            displacementDirection.y -= 0.8f * speed * Time.deltaTime;

        // Normalize
        if (displacementDirection.magnitude > 1) displacementDirection.Normalize();

        // This set the displacement vector in the shader. It is a global variable so all shaders share it
        Shader.SetGlobalVector("_Displacement", displacementDirection);

        // Updating the shell values updates the shader
        if(numShells > shells.Count)
        {
            for(int i = 0; i < numShells - shells.Count; i++)
            {
                GameObject newMesh = Instantiate(meshToDuplicate, transform);
                shells.Add(newMesh);
                newMesh.transform.localPosition = new Vector3(0, 0, 0);
                Material newMat = new Material(papaMaterial);
                newMat.SetInt("_Index", shells.Count);
                newMat.SetInt("_Count", numShells);
                newMesh.GetComponent<MeshRenderer>().material = newMat;
            }
        }
        else if(numShells < shells.Count)
        {
            for(int i = 0; i < shells.Count - numShells; i++)
            {
                Destroy(shells[shells.Count - 1]);
                shells.RemoveAt(shells.Count - 1);
            }
        }

        // Set each shell's parameters in shader
        foreach(GameObject shell in shells)
        {
            Material mat = shell.GetComponent<MeshRenderer>().material;
            mat.SetFloat("_StrandDensity", _StrandDensity);
            mat.SetFloat("_StrandCurve", _StrandCurve);
            mat.SetFloat("_Thickness", _Thickness);
            mat.SetFloat("_Density", _Density);
            mat.SetFloat("_LightPower", _LightPower);
            mat.SetFloat("_AmbientOcclusionPower", _AmbientOcclusionPower);
            mat.SetFloat("_AmbientOcclusionUplift", _AmbientOcclusionUplift);
            mat.SetInt("_AmbientOcclusion", _AmbientOcclusion);
            mat.SetVector("_Color", _Color);
        }
    }
}
