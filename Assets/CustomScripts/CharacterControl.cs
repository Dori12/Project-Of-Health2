using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterControl : MonoBehaviour {

    private List<Transform> nodes;
    private Transform[] pathWayPoint;
    private int wayPointNum;
    public GameObject path;
    public float Speed;

    private Transform tr;
	// Use this for initialization
	void Start () {
        nodes = new List<Transform>();
        Transform[] pathWayPoint = path.GetComponentsInChildren<Transform>();

        for(int i=0; i<pathWayPoint.Length; i++)
        {
            if (pathWayPoint[i] != path.transform)
            {
                nodes.Add(pathWayPoint[i]);
            }
        }
        wayPointNum = 0;

        tr = GetComponent<Transform>();
        Speed = 0.0f;
	}
	
	// Update is called once per frame
	void Update () {
        tr.position = Vector3.MoveTowards(tr.position, nodes[wayPointNum].position, Speed*Time.deltaTime);
        Quaternion newRotation = Quaternion.LookRotation(nodes[wayPointNum].position - tr.position, Vector3.forward);
        newRotation.x = 0.0f;
        newRotation.z = 0.0f;
        tr.rotation = Quaternion.Slerp(tr.rotation, newRotation, 10.0f * Time.deltaTime);
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.gameObject.tag == "WayPoint")
        {
            wayPointNum++;
        }
    }
}
