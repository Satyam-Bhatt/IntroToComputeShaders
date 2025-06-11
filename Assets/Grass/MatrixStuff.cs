using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MatrixStuff : MonoBehaviour
{
    public Vector3 pos = new Vector3(1, 1, 1);
    public Quaternion rot = Quaternion.identity;
    public Vector3 scale = Vector3.one;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Matrix4x4 matrix = Matrix4x4.TRS(pos, rot, scale);

        if(Input.GetKeyDown(KeyCode.Space))
        {
            Debug.Log($"Row 0: {matrix.GetRow(0)}");
            Debug.Log($"Row 1: {matrix.GetRow(1)}");
            Debug.Log($"Row 2: {matrix.GetRow(2)}");
            Debug.Log($"Row 3: {matrix.GetRow(3)}");
        }

        // Extract position from the last column
        transform.position = new Vector3(matrix.m03, matrix.m13, matrix.m23);

        // Extract rotation
        transform.rotation = matrix.rotation;

        // Extract scale (magnitude of the first three columns)
        Vector3 extractedScale = new Vector3(
            matrix.GetColumn(0).magnitude,
            matrix.GetColumn(1).magnitude,
            matrix.GetColumn(2).magnitude
        );
        transform.localScale = extractedScale;
    }
}
