using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Lerping : MonoBehaviour
{
    [Range(0f, 1f)]
    public float lerpValue = 0f;

    private float yValue = 0f;

    public bool startMoving = false;
    public float speed = 1f;

    private void Start()
    {
        yValue = transform.position.y;
    }

    private void Update()
    {
        if (startMoving)
        {
            float val = Mathf.LerpUnclamped(yValue, yValue + 10f, Mathf.Sin(lerpValue * Mathf.PI * 2));
            if(lerpValue <= 1f) lerpValue += speed * Time.deltaTime;
            transform.position = new Vector3(transform.position.x, val, transform.position.z);
        }
    }

    //void Update()
    //{
    //    if (startMoving)
    //    {
    //        //float val = Mathf.Lerp(yValue, yValue + 10f, Mathf.Pow(lerpValue, 2f)); // Curve1 (Ease In)
    //        //float val = Mathf.Lerp(yValue, yValue + 10f, Mathf.Pow(lerpValue, 0.5f)); // Curve2 
    //        //float val = Mathf.Lerp(yValue, yValue + 10f, 1 - Mathf.Pow(1 - lerpValue, 4f)); // Curve3 (Ease Out)
    //        //float val = Mathf.Lerp(yValue, yValue + 10f, 3 * Mathf.Pow(lerpValue, 2f) - 2 * Mathf.Pow(lerpValue, 3f)); // Curve4 (Smooth Step)
    //        float val = Mathf.LerpUnclamped(yValue, yValue + 10f, Mathf.Sin(lerpValue * Mathf.PI * 2)); // Curve5 (Bell)

    //        if (lerpValue <= 1f) lerpValue += 1f * Time.deltaTime;

    //        cube.position = new Vector3(cube.position.x, val, cube.position.z);
    //    }
    //}
}
