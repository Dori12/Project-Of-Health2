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
    public Transform _characterTr;

    private Vector3 _currentLocation;
    private Vector3 _prevLocation;
    private float _velocity;
    int i;
	// Use this for initialization
	void Start () {
        slider = GetComponent<Slider>();
        _playDi.Stop();
        _playDi.Play();
        _velocity = 0.0f;
        _animator.SetFloat("Speed", 0.0f);
        _currentLocation = _characterTr.position;
        _prevLocation = _characterTr.position;
    }

    // Update is called once per frame
    void Update () {
        UpdateVelocity();
        SetSpeed();
        _playDi.time += speed * Time.deltaTime;
    }

    void SetSpeed()
    {
        speed = slider.value * 0.4f;
        _animator.SetFloat("Speed", _velocity * 7500.0f);
    }

    void UpdateVelocity()
    {
        _currentLocation = _characterTr.position;
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

    }
}
