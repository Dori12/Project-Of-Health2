using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR;

public class DisableTracking : MonoBehaviour
{


    public GameObject camGroup;
    public Camera leftCam;
    public Camera rightCam;

    public float fov;
    private float fovMin = 40;
    private float fovMax = 100;

    private float camGroupX = 0;
    private float camGroupXMin = 0;
    private float camGroupXMax = 100;
    private float camGroupXStep = 20;


    // Use this for initialization
    public void Start()
    {
        // set render quality to 50%, sacrificing speed for visual quality
        // this is pretty important on laptops, where the framerate is often quite low
        // 50% quality actually isn't that bad
        //XRSettings.renderScale = 3.0f;

        //OVRTouchpad.Create();
        //OVRTouchpad.TouchHandler += HandleTouchHandler;
        XRDevice.DisableAutoXRCameraTracking(Camera.main, true);

    }

    // Update is called once per frame
    void Update()
    {

        if (Input.GetKeyDown(KeyCode.R))
        {
            InputTracking.Recenter(); // recenter "North" for VR, so that you don't have to twist around randomlys
        }
    }

    public void SetFovZoomFactor()
    {
        XRDevice.fovZoomFactor = GameObject.Find("FovZoomFactor").GetComponent<UnityEngine.UI.Slider>().value;
    }
}