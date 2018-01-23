using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SpeedControl2 : MonoBehaviour {

    private float speed;
    public Slider slider;
    private Animator _animator;
    private Transform _characterTr;
    private CharacterControl _scCharacterControl;


    private Vector3 _currentLocation;
    private Vector3 _prevLocation;
    private float _velocity;
    private float _startVelocity;
    private float _finalVelocity;
    private float checkTime;
    // Use this for initialization
    void Start()
    {
        slider = GetComponent<Slider>();
        _animator = GameObject.FindGameObjectWithTag("Jogger").GetComponent<Animator>();
        _characterTr = GameObject.FindGameObjectWithTag("Jogger").GetComponent<Transform>();
        _scCharacterControl = GameObject.FindGameObjectWithTag("Jogger").GetComponent<CharacterControl>();
        _animator.SetFloat("Speed", 0.0f);
        _currentLocation = _characterTr.position;
        _prevLocation = _characterTr.position;
        checkTime = 0.0f;
        Application.targetFrameRate = 60;
    }

    // Update is called once per frame
    void Update()
    {
        UpdateVelocity();
        SetSpeed();
        _velocity = Mathf.Lerp(_velocity, _finalVelocity, 4.0f * Time.deltaTime);
        _scCharacterControl.Speed = Mathf.Lerp(_scCharacterControl.Speed, speed, 3.0f*Time.deltaTime);
        _scCharacterControl.Speed = Mathf.Clamp(_scCharacterControl.Speed, 0.0f, 10.0f);
        checkTime += Time.deltaTime;
    }

    void SetSpeed()
    {
        speed = slider.value * 10.0f;
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