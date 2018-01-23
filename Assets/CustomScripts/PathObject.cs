using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PathObject : MonoBehaviour {

    public Color lineColor;

    void OnDrawGizmos()
    {
        Gizmos.color = lineColor;
        List<Transform> nodes = new List<Transform>();
        Transform[] pathTransforms = GetComponentsInChildren<Transform>();

        for(int i = 0; i < pathTransforms.Length; i++)
        {
            if(pathTransforms[i] != transform)
            {
                nodes.Add(pathTransforms[i]);
            }
        }

        for(int i=0; i<nodes.Count; i++)
        {
            Vector3 currentNode = nodes[i].position;
            Vector3 previousNode = Vector3.zero;

            if (i > 0)
            {
                previousNode = nodes[i - 1].position;
            }
            else if (i == 0 && nodes.Count > 1)
            {
                previousNode = currentNode;
            }

            Gizmos.DrawLine(previousNode, currentNode);
        }
    }

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
