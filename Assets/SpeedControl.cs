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
    public Rigidbody _characterRbody;
	// Use this for initialization
	void Start () {
        slider = GetComponent<Slider>();
        _playDi.Stop();
        _playDi.Play();
        _animator.SetFloat("Speed", 0.0f);
    }

    // Update is called once per frame
    void Update () {
        //_currentLocation = _characterTr.position;
        SetSpeed();
        _playDi.time += speed * Time.deltaTime;
    }

    void SetSpeed()
    {
        speed = slider.value * 0.4f;
        _animator.SetFloat("Speed", _characterRbody.velocity.magnitude * 400.0f);
    }

    void UpdateVelocity()
    {
    }
}
