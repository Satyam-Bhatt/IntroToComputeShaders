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
}
