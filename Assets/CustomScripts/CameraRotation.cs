using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraRotation : MonoBehaviour {

    public GameObject cam;
    public GameObject target;
    public Vector3 LookPos;
	// Use this for initialization
	void Start () {
        cam = GameObject.Find("Camera (eye)");
        //cam.transform.Rotate(new Vector3(7.4f, 0.0f, 0.0f), Space.Self);
    }
	
	// Update is called once per frame
	void Update () {
        cam.transform.localEulerAngles = new Vector3(7.4f, 0.0f, 0.0f);
        //Vector3 cameraPos = cam.transform.position;
        //Vector3 newLookPos = target.transform.position;
        //LookPos = Vector3.Lerp(LookPos, newLookPos, 1.2f * Time.deltaTime);

        //cam.transform.LookAt(LookPos);
        
    }
}
