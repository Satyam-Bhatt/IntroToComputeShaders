using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraScript : MonoBehaviour
{
    public Transform target;
    public float smoothSpeed = 10f;
    public Vector3 offset = new Vector3(0, 2, -5); // Adjust these values as needed

    void LateUpdate()
    {
        // Check if target exists
        if (target == null)
        {
            Debug.LogWarning("Camera target is not assigned!");
            return;
        }

        // Calculate the desired position for the camera
        Vector3 desiredPosition = target.position + target.TransformDirection(offset);

        // Smoothly move the camera to that position
        Vector3 smoothedPosition = Vector3.Lerp(transform.position, desiredPosition, smoothSpeed * Time.deltaTime);
        transform.position = smoothedPosition;

        // Make the camera look at the target
        transform.LookAt(target.position + Vector3.up);
    }
}
