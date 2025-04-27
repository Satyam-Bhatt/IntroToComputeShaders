using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class movingscript : MonoBehaviour
{
    public float moveSpeed = 5f;
    public float rotationSpeed = 120f;
    public float verticalSpeed = 5f;

    private CharacterController controller;

    void Start()
    {
        // Get the Character Controller component
        controller = GetComponent<CharacterController>();

        // Error handling if no Character Controller is attached
        if (controller == null)
        {
            Debug.LogError("Character Controller component is missing from this GameObject!");
        }
    }

    void Update()
    {
        // Initialize movement vector
        Vector3 moveDirection = Vector3.zero;

        if(Input.GetKeyDown(KeyCode.LeftShift))
        {
            moveSpeed *= 2f;
            verticalSpeed *= 2f;
        }
        if(Input.GetKeyUp(KeyCode.LeftShift))
        {
            moveSpeed /= 2f;
            verticalSpeed /= 2f;
        }

        // Move forward only when W is pressed
        if (Input.GetKey(KeyCode.W))
        {
            moveDirection += transform.forward * moveSpeed;
        }

        // Vertical movement with Q and E
        if (Input.GetKey(KeyCode.Q))
        {
            moveDirection += Vector3.down * verticalSpeed; // Move down
        }

        if (Input.GetKey(KeyCode.E))
        {
            moveDirection += Vector3.up * verticalSpeed; // Move up
        }

        // Apply movement
        controller.Move(moveDirection * Time.deltaTime);

        // Handle rotation with A and D keys
        float rotation = 0f;

        if (Input.GetKey(KeyCode.A))
        {
            rotation = -rotationSpeed;
        }
        else if (Input.GetKey(KeyCode.D))
        {
            rotation = rotationSpeed;
        }

        // Apply rotation
        transform.Rotate(0, rotation * Time.deltaTime, 0);
    }
}
