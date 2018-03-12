using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR;

public class DisableTracking : MonoBehaviour {

	// Use this for initialization
	void Start () {
        InputTracking.disablePositionalTracking = false;
	}
	
	// Update is called once per frame
	void Update () {
            transform.position = -InputTracking.GetLocalPosition(XRNode.CenterEye);
            transform.rotation = Quaternion.Inverse(InputTracking.GetLocalRotation(XRNode.CenterEye));
    }
}