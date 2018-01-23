using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Timeline;
using UnityEngine.Playables;

public class SpeedControl : MonoBehaviour {

    private float speed;
    public Slider slider;
    public Animator _animator;
    public PlayableDirector _playDi;
    public Transform _characterTr;

    private Vector3 _currentLocation;
    private Vector3 _prevLocation;
    private float _velocity;
    private float _startVelocity;
    private float _finalVelocity;
    private float checkTime;
	// Use this for initialization
	void Start () {
        slider = GetComponent<Slider>();
        _playDi.Stop();
        _playDi.Play();
        _animator.SetFloat("Speed", 0.0f);
        _currentLocation = _characterTr.position;
        _prevLocation = _characterTr.position;
        checkTime = 0.0f;
        Application.targetFrameRate = 60;
    }

    // Update is called once per frame
    void Update () {
        UpdateVelocity();
        SetSpeed();
        _velocity = Mathf.Lerp(_velocity, _finalVelocity, 4.0f * Time.deltaTime);
        _playDi.time += speed * Time.deltaTime;
        checkTime += Time.deltaTime;
    }

    void SetSpeed()
    {
        speed = slider.value * 0.4f;
        _animator.SetFloat("Speed", _velocity * 2500.0f);
    }

    void UpdateVelocity()
    {
        
        if (checkTime > 0.016f)
        {
            _currentLocation = _characterTr.position;
            if (speed != 0 && _currentLocation == _prevLocation)
            {
                _finalVelocity = 0.0f;
            }
            else if (speed == 0 && _currentLocation == _prevLocation)
            {
                _finalVelocity = 0.0f;
            }
            else
            {
                Vector3 _transLocation = _currentLocation - _prevLocation;
                _finalVelocity = _transLocation.magnitude;
                _prevLocation = _characterTr.position;
            }
            checkTime = 0.0f;
        }

    }
}
