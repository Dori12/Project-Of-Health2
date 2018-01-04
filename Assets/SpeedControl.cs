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
    private Vector3 _prevLocatoin;
    private float _velocity;
	// Use this for initialization
	void Start () {
        slider = GetComponent<Slider>();
        _playDi.Stop();
        _playDi.Play();
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
        Vector3 _transLocation = _currentLocation - _prevLocatoin;
        _velocity = _transLocation.magnitude;
        _prevLocatoin = _characterTr.position;
    }
}
