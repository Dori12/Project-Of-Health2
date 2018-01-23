using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ViveControllerInput : MonoBehaviour {
    private SteamVR_TrackedObject trackedObj;
    private SpeedControl speedControlObj;
    private bool touchPadDown;

    private SteamVR_Controller.Device Controller
    {
        get { return SteamVR_Controller.Input((int)trackedObj.index); }
    }

    private void Awake()
    {
        trackedObj = GetComponent<SteamVR_TrackedObject>();
        speedControlObj = FindObjectOfType<SpeedControl>().GetComponent<SpeedControl>();
        touchPadDown = false;
    }
    // Update is called once per frame
    void Update () {
        if(Controller.GetAxis() != Vector2.zero)
        {
            if(touchPadDown)
            {
                speedControlObj.slider.value += Controller.GetAxis().x * Time.deltaTime;
            }
            //Debug.Log(gameObject.name + Controller.GetAxis());
        }

        if(Controller.GetPressDown(SteamVR_Controller.ButtonMask.Touchpad))
        {
            //Debug.Log(gameObject.name + " TouchPad Press");
            touchPadDown = true;
        }

        if(Controller.GetPressUp(SteamVR_Controller.ButtonMask.Touchpad))
        {
            //Debug.Log(gameObject.name + "TouchPad Release");
            touchPadDown = false;
        }
        if(Controller.GetHairTriggerDown())
        {
            //Debug.Log(gameObject.name + " Trigger Press");
        }

        if(Controller.GetHairTriggerUp())
        {
            //Debug.Log(gameObject.name + " Trigger Release");
        }

        if(Controller.GetPressDown(SteamVR_Controller.ButtonMask.Grip))
        {
            //Debug.Log(gameObject.name + " Grip Press");
        }

        if(Controller.GetPressUp(SteamVR_Controller.ButtonMask.Grip))
        {
            //Debug.Log(gameObject.name + " Grip Release");
        }
	}
}
