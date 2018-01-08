using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Timeline;
using UnityEngine.Playables;

public class SpeedControl : MonoBehaviour {

    private float speed;
    private Slider slider;
    public Animator _animator;
    public PlayableDirector _playDi;
<<<<<<< HEAD
    public Rigidbody _characterRbody;
=======
    public Transform _characterTr;

    private Vector3 _currentLocation;
    private Vector3 _prevLocation;
    private float _velocity;
    private float checkTime;
>>>>>>> 2cbfb3698da9cce00e755ffb7cb68c002e9a1cef
	// Use this for initialization
	void Start () {
        slider = GetComponent<Slider>();
        _playDi.Stop();
        _playDi.Play();
        _animator.SetFloat("Speed", 0.0f);
<<<<<<< HEAD
=======
        _currentLocation = _characterTr.position;
        _prevLocation = _characterTr.position;
        checkTime = 0.0f;
>>>>>>> 2cbfb3698da9cce00e755ffb7cb68c002e9a1cef
    }

    // Update is called once per frame
    void Update () {
        //_currentLocation = _characterTr.position;
        SetSpeed();
        _playDi.time += speed * Time.deltaTime;
        checkTime += Time.deltaTime;
    }

    void SetSpeed()
    {
        speed = slider.value * 0.4f;
<<<<<<< HEAD
        _animator.SetFloat("Speed", _characterRbody.velocity.magnitude * 400.0f);
=======
        _animator.SetFloat("Speed", _velocity * 2500.0f);
>>>>>>> 2cbfb3698da9cce00e755ffb7cb68c002e9a1cef
    }

    void UpdateVelocity()
    {
<<<<<<< HEAD
=======
        _currentLocation = _characterTr.position;
        if (checkTime > 1 / 60)
        {
            Vector3 _transLocation = _currentLocation - _prevLocation;
            if (speed != 0 && _currentLocation == _prevLocation)
            {
            }
            else if (speed == 0 && _currentLocation == _prevLocation)
            {

            }
            else
            {
                _velocity = _transLocation.magnitude;
            }
            _prevLocation = _characterTr.position;
            checkTime = 0.0f;
        }

>>>>>>> 2cbfb3698da9cce00e755ffb7cb68c002e9a1cef
    }
}
