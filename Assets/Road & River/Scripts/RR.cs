using UnityEngine;
[ExecuteInEditMode()]
public class RR : MonoBehaviour
{
    public void Start()
    {
        Terrain terComponent = (Terrain)gameObject.GetComponent(typeof(Terrain));
        if (terComponent == null)
            Debug.LogError("This script must be attached to a terrain object");
    }

    public void NewPath()
    {
        GameObject pathMesh = new GameObject();
        pathMesh.name = "Path";
        pathMesh.AddComponent(typeof(MeshFilter));
        pathMesh.AddComponent(typeof(MeshRenderer));
        pathMesh.AddComponent<RRAttached>();
        RRAttached RR = (RRAttached)pathMesh.GetComponent("RRAttached");
        RR.pathMesh = pathMesh;
        RR.parentTerrain = gameObject;
        RR.NewPath();


    }
}


