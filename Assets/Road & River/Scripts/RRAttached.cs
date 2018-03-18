using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
[ExecuteInEditMode()]
[Serializable]
public class PathNodeObjects
{
    public Quaternion rotation;
    public Vector3 position;
    public float width;

    public static explicit operator UnityEngine.Object(PathNodeObjects v)
    {
        throw new NotImplementedException();
    }
}
public struct TerrainPathCell
{
    public float heightAtCell;
    public Vector2 position;
    public bool isAdded;
}
public class RRAttached : MonoBehaviour
{
    public int index;
    public bool costil = false;
    public float UV = 1;
    public bool enableTexturing;
    public TerrainPathCell[] terrainCells;
    public bool addNodeMode;
    public bool isRoad = true;
    public bool isFinalized;
    public bool alignTerrainToRoad;
    public bool enableVegetation = false;
    public float detailRemoveWidth = 1f;
    public float treeRemoveWidth = 1f;
    public List<PathNodeObjects> nodeObjects;
    public Vector3[] nodeObjectVerts;
    public bool alignToTerrain;
    public GameObject pathMesh;
    public MeshCollider pathCollider;
    public ArrayList pathCells;
    public ArrayList totalPathVerts;
    public ArrayList innerPathVerts;
    public float terrainDepth = 2f;
    public float terrainWidth = 2;
    public float pathWidth = 3f;
    public float sturns = 1f;
    public bool roadSlopes = false;
    public float TexturesWidth = 2f;
    public int pathTexture;
    public bool showHandles;
    public float pathWear;
    public int pathSmooth = 6;
    public Vector3[] newVertices;
    public GameObject parentTerrain;
    public GameObject terrainObj;
    public Terrain terComponent;
    public TerrainData terData;
    public TerrainCollider terrainCollider;
    public float[,] terrainHeights;
    public bool ring;

    public void Awake()
    {
        terComponent = (Terrain)parentTerrain.GetComponent(typeof(Terrain));
        if (terComponent == null)
            Debug.LogError("This script must be attached to a terrain object");
    }

    public void NewPath()
    {
        nodeObjects = new List<PathNodeObjects>(1);
        pathCollider = (MeshCollider)pathMesh.AddComponent(typeof(MeshCollider));

        terrainObj = parentTerrain;
        terComponent = (Terrain)terrainObj.GetComponent(typeof(Terrain));

        if (terComponent == null)
            Debug.LogError("This script must be attached to a terrain object");

        terData = terComponent.terrainData;
        terrainHeights = terData.GetHeights(0, 0, terData.heightmapResolution, terData.heightmapResolution);
        terrainCollider = (TerrainCollider)terrainObj.GetComponent(typeof(TerrainCollider));
    }

    public void CreatePathNode(TerrainPathCell nodeCell)
    {
        Vector3 pathPosition = new Vector3((nodeCell.position.x / terData.heightmapResolution) * terData.size.x,
            nodeCell.heightAtCell * terData.size.y,
            (nodeCell.position.y / terData.heightmapResolution) * terData.size.z);
        PathNodeObjects newPathNodeObject = new PathNodeObjects();
        newPathNodeObject.width = pathWidth;
        newPathNodeObject.position = pathPosition;
        newPathNodeObject.rotation = transform.rotation;
        nodeObjects.Add(newPathNodeObject);
        CreatePath(pathSmooth);
    }

    public void CreatePath(int smoothingLevel)
    {
        MeshFilter meshFilter = (MeshFilter)pathMesh.GetComponent(typeof(MeshFilter));

        if (meshFilter == null)
            return;

        Mesh newMesh = meshFilter.sharedMesh;
        terrainHeights = terData.GetHeights(0, 0, terData.heightmapResolution, terData.heightmapResolution);

        pathCells = new ArrayList();

        if (newMesh == null)
        {
            newMesh = new Mesh();
            newMesh.name = "Generated Path Mesh";
            meshFilter.sharedMesh = newMesh;
        }

        else
            newMesh.Clear();


        if (nodeObjects == null || nodeObjects.Count < 2)
        {
            return;
        }

        int n = nodeObjects.Count;

        int verticesPerNode = 2 * (smoothingLevel + 1) * 2;
        int trianglesPerNode = 6 * (smoothingLevel + 1);
        Vector2[] uvs;
        int[] newTriangles;
        uvs = new Vector2[(verticesPerNode * (n - 1))];
        newVertices = new Vector3[(verticesPerNode * (n - 1))];
        newTriangles = new int[(trianglesPerNode * (n - 1))];
        nodeObjectVerts = new Vector3[(verticesPerNode * (n - 1))];
        int nextVertex = 0;
        int nextTriangle = 0;
        int nextUV = 0;
        float[] cubicX = new float[n];
        float[] cubicZ = new float[n];
        float[] cubicY = new float[n];
        Vector3 handle1Tween = new Vector3();
        Vector3[] g1 = new Vector3[smoothingLevel + 1];
        Vector3[] g2 = new Vector3[smoothingLevel + 1];
        Vector3[] g3 = new Vector3[smoothingLevel + 1];
        Vector3 oldG2 = new Vector3();
        Vector3 extrudedPointL = new Vector3();
        Vector3 extrudedPointR = new Vector3();
        Vector3 extrudedPointLf, extrudedPointRf;
        Vector3 extrudedPointLfOld = Vector3.zero;
        Vector3 extrudedPointRfOld = Vector3.zero;
        Vector3 extrudedPointLfFirst = Vector3.zero;
        Vector3 extrudedPointRfFirst = Vector3.zero;
        if (ring)
        {

            Vector3 middlePos = (nodeObjects[nodeObjects.Count - 1].position + nodeObjects[0].position) / 2;
            Quaternion middlerotate = Quaternion.Euler((nodeObjects[nodeObjects.Count - 1].rotation.eulerAngles + nodeObjects[0].rotation.eulerAngles) / 2);

            nodeObjects[0].position = middlePos;
            nodeObjects[0].rotation = middlerotate;
            nodeObjects[nodeObjects.Count - 1].position = middlePos;
            nodeObjects[nodeObjects.Count - 1].rotation = middlerotate;
        }

        for (int i = 0; i < n; i++)
        {
            cubicX[i] = nodeObjects[i].position.x;
            cubicZ[i] = nodeObjects[i].position.z;
            cubicY[i] = nodeObjects[i].position.y;
        }
        for (int i = 0; i < n; i++)
        {
            g1 = new Vector3[smoothingLevel + 1];
            g2 = new Vector3[smoothingLevel + 1];
            g3 = new Vector3[smoothingLevel + 1];

            extrudedPointL = new Vector3();
            extrudedPointR = new Vector3();

            if (i == 0)
            {

                newVertices[nextVertex] = nodeObjects[0].position;
                nextVertex++;
                uvs[0] = new Vector2(0f, 1f);
                nextUV++;
                newVertices[nextVertex] = nodeObjects[0].position;
                nextVertex++;
                uvs[1] = new Vector2(1f, 1f);
                nextUV++;
                continue;
            }
            float _widthAtNode = pathWidth;
            Cubic[] X;
            Cubic[] Z;
            Cubic[] Y;
            Vector3 tweenPoint;
            float u;
            for (int j = 0; j < smoothingLevel + 1; j++)
            {
                if (i == 1)
                {
                    if (j != 0)
                    {
                        newVertices[nextVertex] = newVertices[nextVertex - 2];
                        nextVertex++;

                        newVertices[nextVertex] = newVertices[nextVertex - 2];
                        nextVertex++;

                        uvs[nextUV] = new Vector2(0f, 1f);
                        nextUV++;
                        uvs[nextUV] = new Vector2(1f, 1f);
                        nextUV++;
                    }
                    else
                    {
                        oldG2 = nodeObjects[0].position;
                    }

                }
                else
                {
                    newVertices[nextVertex] = newVertices[nextVertex - 2];
                    nextVertex++;

                    newVertices[nextVertex] = newVertices[nextVertex - 2];
                    nextVertex++;

                    uvs[nextUV] = new Vector2(0f, 1f * UV);
                    nextUV++;

                    uvs[nextUV] = new Vector2(1f, 1f * UV);
                    nextUV++;

                }

                u = (float)(j + 1) / (float)(smoothingLevel + 1f);

                X = calcNaturalCubic(n - 1, cubicX);
                Z = calcNaturalCubic(n - 1, cubicZ);
                Y = calcNaturalCubic(n - 1, cubicY);
                tweenPoint = new Vector3(X[i - 1].eval(u), Y[i - 1].eval(u), Z[i - 1].eval(u));

                TerrainPathCell tC = new TerrainPathCell();
                tC.position.x = ((tweenPoint.x - parentTerrain.transform.position.x) / terData.size.x) * terData.heightmapResolution;
                tC.position.y = ((tweenPoint.z - parentTerrain.transform.position.z) / terData.size.z) * terData.heightmapResolution;
                tC.heightAtCell = (tweenPoint.y - parentTerrain.transform.position.y) / terData.size.y;
                pathCells.Add(tC);
                if (i == 1)
                {

                    if (j == 0)
                    {
                        handle1Tween = tweenPoint;
                    }
                }


                g2[j] = tweenPoint;
                g1[j] = oldG2;
                g3[j] = (g2[j] - g1[j]);
                oldG2 = g2[j];
                extrudedPointL = new Vector3(-g3[j].z, g3[j].y, g3[j].x);
                extrudedPointR = new Vector3(g3[j].z, g3[j].y, -g3[j].x);
                if (roadSlopes)
                {
                    extrudedPointL = new Vector3(-g3[j].z, g3[j].y, g3[j].x);
                    extrudedPointR = new Vector3(g3[j].z, g3[j].y, -g3[j].x);
                    if (j == 0 && i == 1)
                    {

                        extrudedPointLfOld = extrudedPointL *= _widthAtNode;
                        extrudedPointRfOld = extrudedPointR *= _widthAtNode;
                    }
                    extrudedPointLf = nodeObjects[i].rotation * extrudedPointL;
                    extrudedPointRf = nodeObjects[i].rotation * extrudedPointR;
                    extrudedPointL = ((extrudedPointLfOld + new Vector3(((extrudedPointLf.x / smoothingLevel) * j), ((extrudedPointLf.y / smoothingLevel) * j), ((extrudedPointLf.z / smoothingLevel) * j))) / 2);
                    extrudedPointR = ((extrudedPointRfOld + new Vector3(((extrudedPointRf.x / smoothingLevel) * j), ((extrudedPointRf.y / smoothingLevel) * j), ((extrudedPointRf.z / smoothingLevel) * j))) / 2);
                    if (j == smoothingLevel)
                    {
                        extrudedPointL.Normalize();
                        extrudedPointR.Normalize();
                        extrudedPointLfOld = extrudedPointL;
                        extrudedPointRfOld = extrudedPointR;
                        if (i == 1)
                        {
                            extrudedPointLfFirst = extrudedPointLfOld;
                            extrudedPointRfFirst = extrudedPointRfOld;
                        }
                    }

                }
                extrudedPointL.Normalize();
                extrudedPointR.Normalize();
                extrudedPointL *= _widthAtNode;
                extrudedPointR *= _widthAtNode;
                newVertices[nextVertex] = tweenPoint + extrudedPointR;

                nodeObjectVerts[nextVertex] = newVertices[nextVertex];
                nextVertex++;

                newVertices[nextVertex] = tweenPoint + extrudedPointL;

                nodeObjectVerts[nextVertex] = newVertices[nextVertex];
                nextVertex++;

                uvs[nextUV] = new Vector2(0f, 0f);
                nextUV++;
                uvs[nextUV] = new Vector2(1f, 0f);
                nextUV++;




                // Create triangles...
                newTriangles[nextTriangle] = (verticesPerNode * (i - 1)) + (4 * j); // 0
                nextTriangle++;
                newTriangles[nextTriangle] = (verticesPerNode * (i - 1)) + (4 * j) + 1; // 1
                nextTriangle++;
                newTriangles[nextTriangle] = (verticesPerNode * (i - 1)) + (4 * j) + 2; // 2
                nextTriangle++;
                newTriangles[nextTriangle] = (verticesPerNode * (i - 1)) + (4 * j) + 1; // 1
                nextTriangle++;
                newTriangles[nextTriangle] = (verticesPerNode * (i - 1)) + (4 * j) + 3; // 3
                nextTriangle++;
                newTriangles[nextTriangle] = (verticesPerNode * (i - 1)) + (4 * j) + 2; // 2
                nextTriangle++;
            }
        }

        g2[0] = handle1Tween;
        g1[0] = nodeObjects[0].position;
        g3[0] = g2[0] - g1[0];

        extrudedPointL = new Vector3(-g3[0].z, g3[0].y, g3[0].x);
        extrudedPointR = new Vector3(g3[0].z, g3[0].y, -g3[0].x);
        if (roadSlopes)
        {
            extrudedPointLf = nodeObjects[0].rotation * extrudedPointL;
            extrudedPointRf = nodeObjects[0].rotation * extrudedPointR;
            extrudedPointL = ((extrudedPointLfFirst + new Vector3(0, ((extrudedPointLf.y / smoothingLevel) * smoothingLevel), 0)) / 2);
            extrudedPointR = ((extrudedPointRfFirst + new Vector3(0, ((extrudedPointRf.y / smoothingLevel) * smoothingLevel), 0)) / 2);
        }
        extrudedPointL.Normalize();
        extrudedPointR.Normalize();
        extrudedPointL *= pathWidth;
        extrudedPointR *= pathWidth;
        newVertices[0] = nodeObjects[0].position + extrudedPointR;
        newVertices[1] = nodeObjects[0].position + extrudedPointL;

        Vector3 vertposz = newVertices[0];
        Vector3 vertposo = newVertices[1];
        if (roadSlopes)
        {
            for (int k = 2; k < smoothingLevel * 2;)
            {
                newVertices[k].y += (vertposz.y - nodeObjects[0].position.y) * (1f - ((1f / (smoothingLevel * 2)) * (k - 2)));
                k++;
                newVertices[k].y += (vertposo.y - nodeObjects[0].position.y) * (1f - ((1f / (smoothingLevel * 2)) * (k - 3)));
                newVertices[k + 1] = newVertices[k - 1];
                newVertices[k + 2] = newVertices[k];
                k++;
                k++;
                k++;
            }
        }
        if (alignToTerrain == true)
        {
            for (int i = 0; i < newVertices.Length; i++)
            {
                newVertices[i].y = terComponent.SampleHeight(newVertices[i]) + (0.01f + index * 0.005f) + parentTerrain.transform.position.y;
            }
        }
        if (ring)
        {
            newVertices[newVertices.Length - 1] = newVertices[1];
            newVertices[newVertices.Length - 2] = newVertices[0];
        }
        newMesh.vertices = newVertices;
        newMesh.triangles = newTriangles;
        Color[] colors = new Color[newMesh.vertices.Length];
        int countVertex = newMesh.vertices.Length;
        colors[countVertex - 1] = new Color(1f, 0, 0);
        colors[countVertex - 2] = new Color(1f, 0, 0);
        colors[countVertex - 3] = new Color(0f, 0, 0);
        colors[countVertex - 4] = new Color(0f, 0, 0);
        colors[0] = new Color(1f, 0, 0);
        colors[1] = new Color(1f, 0, 0);
        colors[2] = new Color(0f, 0, 0);
        colors[3] = new Color(0f, 0, 0);
        newMesh.colors = colors;
        uvs = new Vector2[newMesh.vertices.Length];

        float distance = 0f;
        for (int i = 0; i < newMesh.vertices.Length; i += 4)
        {
            uvs[i] = new Vector2(0f, distance);
            uvs[i + 1] = new Vector2(1f, distance);
            distance += Vector3.Distance(
                (newMesh.vertices[i] + newMesh.vertices[i + 1]) * (UV * 0.1f),
                (newMesh.vertices[i + 2] + newMesh.vertices[i + 3]) * (UV * 0.1f)
            );
            uvs[i + 2] = new Vector2(0f, distance);
            uvs[i + 3] = new Vector2(1f, distance);
        }


        newMesh.uv = uvs;
        Vector3[] myNormals = new Vector3[newMesh.vertexCount];
        for (int p = 0; p < newMesh.vertexCount; p++)
        {
            myNormals[p] = Vector3.up;
            myNormals[p] = myNormals[p].normalized;
        }

        newMesh.normals = myNormals;

        TangentSolver(newMesh);
        pathMesh.GetComponent<Renderer>().enabled = true;
        pathMesh.GetComponent<MeshRenderer>().receiveShadows = true;
        pathMesh.GetComponent<MeshRenderer>().shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
        newMesh.RecalculateNormals();
        pathCollider.sharedMesh = meshFilter.sharedMesh;

        if (!costil)
        {
            pathMesh.GetComponent<MeshRenderer>().material = (Material)Resources.Load("Material/Asphalt_01", typeof(Material));
            costil = true;
        }
        pathMesh.GetComponent<Renderer>().enabled = true;
        transform.localScale = new Vector3(1, 1, 1);
    }
    float AnglePoint(Vector3 a, Vector3 b, Vector3 c)
    {

        return Mathf.Atan2(
            Vector3.Dot(c, Vector3.Cross(a, b)),
            Vector3.Dot(a, b)) * Mathf.Rad2Deg;
    }





    public void Deletepoint(Vector3 nodeCell)
    {
        float[] array = new float[nodeObjects.Count];
        Vector3 Offset1;
        for (int i = 0; i < nodeObjects.Count; i++)
        {
            Offset1 = nodeCell - nodeObjects[i].position;
            array[i] = Offset1.magnitude;
        }
        if (array.Length != 0)
        {
            float minVal = array.Min();
            int indexMin = Array.IndexOf(array, minVal);

            nodeObjects.RemoveAt(indexMin);
            CreatePath(pathSmooth);
        }

    }

    public void Addpoint(TerrainPathCell nodeCell)
    {
        float[] array = new float[nodeObjects.Count];
        Vector3 Offset1;
        Vector3 pathPosition = new Vector3((nodeCell.position.x / terData.heightmapResolution) * terData.size.x,
            nodeCell.heightAtCell * terData.size.y,
            (nodeCell.position.y / terData.heightmapResolution) * terData.size.z);
        PathNodeObjects newPathNodeObject = new PathNodeObjects();
        newPathNodeObject.width = pathWidth;
        newPathNodeObject.position = pathPosition;
        newPathNodeObject.rotation = transform.rotation;
        for (int i = 0; i < nodeObjects.Count; i++)
        {
            Offset1 = (pathPosition - nodeObjects[i].position);
            array[i] = Offset1.magnitude;
        }
        float minVal = array.Min();
        int indexMin = Array.IndexOf(array, minVal);
        array[indexMin] = 999999999f;
        float minVal2 = array.Min();
        int indexMin2 = Array.IndexOf(array, minVal2);

        if (indexMin == 0)
        {
            nodeObjects.Insert(indexMin + 1, newPathNodeObject);
            CreatePath(pathSmooth);
        }
        else
        {
            if (indexMin == nodeObjects.Count - 1)
            {
                nodeObjects.Insert(indexMin, newPathNodeObject);
                CreatePath(pathSmooth);
            }
            else
            {
                if (indexMin2 - 1 == indexMin)
                {
                    nodeObjects.Insert(indexMin2, newPathNodeObject);
                    CreatePath(pathSmooth);
                }
                else
                {
                    nodeObjects.Insert(indexMin, newPathNodeObject);
                    CreatePath(pathSmooth);
                }
            }
        }
    }
    public bool FinalizePath()
    {
        float oldWidthPath = 0;
        oldWidthPath = pathWidth;
        transform.localScale = new Vector3(1, 1, 1);
        if (terData.alphamapLayers > pathTexture || isRoad)
        {
            float[,] tempLRheightmap = terData.GetHeights(0, 0, terData.heightmapResolution, terData.heightmapResolution);
            float[,,] alphamap = terData.GetAlphamaps(0, 0, terData.alphamapWidth, terData.alphamapHeight);
            innerPathVerts = new ArrayList();
            totalPathVerts = new ArrayList();
            ArrayList roadVerts = new ArrayList();
            Vector3 returnCollision = new Vector3();
            pathMesh.transform.Translate(0f, -150f, 0f);
            int detailRadius = (int)((float)terData.detailResolution / (terData.heightmapResolution - 1));
            if (alignTerrainToRoad == true)
            {
                pathWidth += 7;
                CreatePath((int)(pathSmooth / 2));
                foreach (TerrainPathCell tC in terrainCells)
                {
                    RaycastHit raycastHit = new RaycastHit();
                    Ray pathRay = new Ray(new Vector3(
                        (float)((tC.position.x * terData.size.x) / terData.heightmapResolution) + parentTerrain.transform.position.x,
                        (float)tC.heightAtCell * terData.size.y + parentTerrain.transform.position.y,
                        (float)((tC.position.y * terData.size.z) / terData.heightmapResolution) + parentTerrain.transform.position.z), -Vector3.up);
                    if (pathCollider.Raycast(pathRay, out raycastHit, Mathf.Infinity))
                    {
                        innerPathVerts.Add(tC);
                    }
                }
                pathWidth -= 7;
                CreatePath((int)(pathSmooth / 2));
                foreach (TerrainPathCell tC in terrainCells)
                {
                    RaycastHit raycastHit = new RaycastHit();
                    Ray pathRay = new Ray(new Vector3(
                        (float)((tC.position.x * terData.size.x) / terData.heightmapResolution) + parentTerrain.transform.position.x,
                        (float)tC.heightAtCell * terData.size.y + parentTerrain.transform.position.y,
                        (float)((tC.position.y * terData.size.z) / terData.heightmapResolution) + parentTerrain.transform.position.z), -Vector3.up);
                    if (pathCollider.Raycast(pathRay, out raycastHit, Mathf.Infinity))
                    {
                        roadVerts.Add(tC);
                    }
                }
                pathWidth += 7;
                pathWidth += terrainWidth * 4;
                CreatePath((int)(pathSmooth / 2));
                foreach (TerrainPathCell tC in terrainCells)
                {
                    RaycastHit raycastHit = new RaycastHit();
                    Ray pathRay = new Ray(new Vector3(
                        (float)((tC.position.x * terData.size.x) / terData.heightmapResolution) + parentTerrain.transform.position.x,
                        (float)tC.heightAtCell * terData.size.y + parentTerrain.transform.position.y,
                        (float)((tC.position.y * terData.size.z) / terData.heightmapResolution) + parentTerrain.transform.position.z), -Vector3.up);
                    if (pathCollider.Raycast(pathRay, out raycastHit, Mathf.Infinity))
                    {
                        returnCollision = raycastHit.point;
                        returnCollision.y = ((returnCollision.y) - parentTerrain.transform.position.y) / terData.size.y;
                        tempLRheightmap[(int)(tC.position.y), (int)(tC.position.x)] = returnCollision.y + ((float)(150f / terData.size.y));
                        totalPathVerts.Add(tC);
                    }
                }
                pathWidth = oldWidthPath;
            }
            if (enableVegetation)
            {
                pathWidth += detailRemoveWidth;
                CreatePath((int)(pathSmooth / 2));
                foreach (TerrainPathCell tC in terrainCells)
                {
                    RaycastHit raycastHit = new RaycastHit();
                    Ray pathRay = new Ray(new Vector3(
                        (float)((tC.position.x * terData.size.x) / terData.heightmapResolution) + parentTerrain.transform.position.x,
                        (float)tC.heightAtCell * terData.size.y + parentTerrain.transform.position.y,
                        (float)((tC.position.y * terData.size.z) / terData.heightmapResolution) + parentTerrain.transform.position.z), -Vector3.up);
                    if (pathCollider.Raycast(pathRay, out raycastHit, Mathf.Infinity))
                    {
                        for (int i = 0; i < terData.detailPrototypes.Length; i++)
                        {
                            int[,] detailLayer = terData.GetDetailLayer(0, 0, terData.detailResolution, terData.detailResolution, i);

                            for (int j = -detailRadius; j < detailRadius; j++)
                            {
                                for (int k = -detailRadius; k < detailRadius; k++)
                                {
                                    detailLayer[(int)(((float)tC.position.y / terData.heightmapResolution) * terData.detailResolution) + j, (int)(((float)tC.position.x / terData.heightmapResolution) * terData.detailResolution) + k] = 0;
                                }
                            }
                            terData.SetDetailLayer(0, 0, i, detailLayer);
                        }
                    }
                }
                TreeInstance[] trees = terData.treeInstances;
                ArrayList newTrees = new ArrayList();
                Vector3 terrainDataSize = terData.size;
                Vector3 activeTerrainPosition = terComponent.GetPosition();
                float distance;
                foreach (TreeInstance tree in trees)
                {
                    newTrees.Add(tree);
                }
                foreach (TreeInstance tree in trees)
                {
                    for (int i = 0; i < newVertices.Length - 1; i++)
                    {

                        distance = Vector3.Distance(Vector3.Scale(tree.position, terrainDataSize)
                                        + activeTerrainPosition, (newVertices[i] + newVertices[i + 1]) / 2);

                        if (distance < pathWidth + treeRemoveWidth)
                        {
                            newTrees.Remove(tree);
                        }
                    }

                }
                terData.treeInstances = (TreeInstance[])newTrees.ToArray(typeof(TreeInstance));
                pathWidth = oldWidthPath;
                newTrees.Clear();
            }


            if (enableTexturing)
            {
                pathWidth += TexturesWidth;
                CreatePath((int)(pathSmooth / 2));
                foreach (TerrainPathCell tC in terrainCells)
                {
                    RaycastHit raycastHit = new RaycastHit();
                    Ray pathRay = new Ray(new Vector3(
                        (float)((tC.position.x * terData.size.x) / terData.heightmapResolution) + parentTerrain.transform.position.x,
                        (float)tC.heightAtCell * terData.size.y + parentTerrain.transform.position.y,
                        (float)((tC.position.y * terData.size.z) / terData.heightmapResolution) + parentTerrain.transform.position.z), -Vector3.up);
                    if (pathCollider.Raycast(pathRay, out raycastHit, Mathf.Infinity))
                    {
                        for (int i = 0; i < terData.alphamapLayers; i++)
                        {
                            if (alphamap[Convert.ToInt32((tC.position.y / terData.heightmapResolution) * terData.alphamapResolution),
                                Convert.ToInt32((tC.position.x / terData.heightmapResolution) * terData.alphamapResolution), i] > 0.0f)
                            {
                                alphamap[Convert.ToInt32((tC.position.y / terData.heightmapResolution) * terData.alphamapResolution),
                                    Convert.ToInt32((tC.position.x / terData.heightmapResolution) * terData.alphamapResolution), i] = 0;
                            }
                        }
                        alphamap[Convert.ToInt32((tC.position.y / terData.heightmapResolution) * terData.alphamapResolution),
                            Convert.ToInt32((tC.position.x / terData.heightmapResolution) * terData.alphamapResolution), pathTexture] = 1f;
                    }
                }
                pathWidth = oldWidthPath;
            }

            pathWidth = oldWidthPath;
            pathMesh.transform.Translate(0f, 150f, 0f);
            if (alignTerrainToRoad == true)
            {
                terData.SetHeights(0, 0, tempLRheightmap);

                AreaSmooth(innerPathVerts, 1.0f, false);

                foreach (TerrainPathCell tv in totalPathVerts)
                    terrainCells[Convert.ToInt32((tv.position.y) + ((tv.position.x) * (terData.heightmapResolution)))].isAdded = false;

                AreaSmooth(innerPathVerts, 1.0f, false);

                foreach (TerrainPathCell tv in totalPathVerts)
                    terrainCells[Convert.ToInt32((tv.position.y) + ((tv.position.x) * (terData.heightmapResolution)))].isAdded = false;

                AreaSmooth(totalPathVerts, 1.0f, true);

                foreach (TerrainPathCell tv in totalPathVerts)
                    terrainCells[Convert.ToInt32((tv.position.y) + ((tv.position.x) * (terData.heightmapResolution)))].isAdded = false;

                AreaSmooth(totalPathVerts, 1.0f, true);

                foreach (TerrainPathCell tv in totalPathVerts)
                    terrainCells[Convert.ToInt32((tv.position.y) + ((tv.position.x) * (terData.heightmapResolution)))].isAdded = false;

                AreaSmooth(innerPathVerts, 1.0f, false);

                foreach (TerrainPathCell tv in totalPathVerts)
                    terrainCells[Convert.ToInt32((tv.position.y) + ((tv.position.x) * (terData.heightmapResolution)))].isAdded = false;

                float[,] newTerrainHeights = terData.GetHeights(0, 0, terData.heightmapResolution, terData.heightmapResolution);
                foreach (TerrainPathCell pv in roadVerts)
                {
                    if (pathWidth < 10)
                        newTerrainHeights[(int)pv.position.y, (int)pv.position.x] -= terrainDepth * 0.001f;
                    else
                        newTerrainHeights[(int)pv.position.y, (int)pv.position.x] -= terrainDepth * 0.002f;
                }
                terData.SetHeights(0, 0, newTerrainHeights);


                AreaSmooth(innerPathVerts, 1.0f, false);

                foreach (TerrainPathCell tv in totalPathVerts)
                    terrainCells[Convert.ToInt32((tv.position.y) + ((tv.position.x) * (terData.heightmapResolution)))].isAdded = false;

                AreaSmooth(innerPathVerts, 1.0f, false);

                foreach (TerrainPathCell tv in totalPathVerts)
                    terrainCells[Convert.ToInt32((tv.position.y) + ((tv.position.x) * (terData.heightmapResolution)))].isAdded = false;

                AreaSmooth(innerPathVerts, 1.0f, false);

                foreach (TerrainPathCell tv in totalPathVerts)
                    terrainCells[Convert.ToInt32((tv.position.y) + ((tv.position.x) * (terData.heightmapResolution)))].isAdded = false;

                AreaSmooth(totalPathVerts, 1.0f, true);

                foreach (TerrainPathCell tv in totalPathVerts)
                    terrainCells[Convert.ToInt32((tv.position.y) + ((tv.position.x) * (terData.heightmapResolution)))].isAdded = false;

                AreaSmooth(totalPathVerts, 1.0f, true);

                foreach (TerrainPathCell tv in totalPathVerts)
                    terrainCells[Convert.ToInt32((tv.position.y) + ((tv.position.x) * (terData.heightmapResolution)))].isAdded = false;

                if (pathWidth > 10)
                {
                    AreaSmooth(innerPathVerts, 1.0f, false);

                    foreach (TerrainPathCell tv in totalPathVerts)
                        terrainCells[Convert.ToInt32((tv.position.y) + ((tv.position.x) * (terData.heightmapResolution)))].isAdded = false;

                    AreaSmooth(innerPathVerts, 1.0f, false);

                    foreach (TerrainPathCell tv in totalPathVerts)
                        terrainCells[Convert.ToInt32((tv.position.y) + ((tv.position.x) * (terData.heightmapResolution)))].isAdded = false;

                    AreaSmooth(innerPathVerts, 1.0f, false);

                    foreach (TerrainPathCell tv in totalPathVerts)
                        terrainCells[Convert.ToInt32((tv.position.y) + ((tv.position.x) * (terData.heightmapResolution)))].isAdded = false;
                }
                CreatePath(pathSmooth);
            }
            terData.SetAlphamaps(0, 0, alphamap);
            return true;
        }
        else
        {
            Debug.LogError("Invalid texture prototype");
            return false;
        }
    }

    public void AreaSmooth(ArrayList terrainList, float blendAmount, bool exclusion)
    {
        TerrainPathCell tc;
        TerrainPathCell lh;
        float[,] blendLRheightmap = terData.GetHeights(0, 0, terData.heightmapResolution, terData.heightmapResolution);
        if (exclusion)
        {
            foreach (TerrainPathCell tC in innerPathVerts)
            {
                terrainCells[Convert.ToInt32((tC.position.y) + ((tC.position.x) * (terData.heightmapResolution)))].isAdded = true;
            }
        }
        for (int i = 0; i < terrainList.Count; i++)
        {
            tc = (TerrainPathCell)terrainList[i];
            ArrayList locals = new ArrayList();

            if (exclusion)
            {
                for (int x = 2; x > -3; x--)
                {
                    for (int y = 2; y > -3; y--)
                    {
                        if (terrainCells[Convert.ToInt32((tc.position.y + y) + ((tc.position.x + x) * (terData.heightmapResolution)))].isAdded == false)
                        {
                            locals.Add(terrainCells[Convert.ToInt32((tc.position.y + y) + ((tc.position.x + x) * (terData.heightmapResolution)))]);
                            terrainCells[Convert.ToInt32((tc.position.y + y) + ((tc.position.x + x) * (terData.heightmapResolution)))].isAdded = true;
                        }
                    }
                }
            }
            else
            {
                for (int x = 0; x > -1; x--)
                {
                    for (int y = 0; y > -1; y--)
                    {
                        if (terrainCells[Convert.ToInt32((tc.position.y + y) + ((tc.position.x + x) * (terData.heightmapResolution)))].isAdded == false)
                        {
                            locals.Add(terrainCells[Convert.ToInt32((tc.position.y + y) + ((tc.position.x + x) * (terData.heightmapResolution)))]);
                            terrainCells[Convert.ToInt32((tc.position.y + y) + ((tc.position.x + x) * (terData.heightmapResolution)))].isAdded = true;
                        }
                    }
                }
            }
            for (int p = 0; p < locals.Count; p++)
            {
                lh = (TerrainPathCell)locals[p];
                ArrayList localHeights = new ArrayList();
                float cumulativeHeights = 0f;
                for (int x = 1; x > -2; x--)
                {
                    for (int y = 1; y > -2; y--)
                    {
                        localHeights.Add(terrainCells[Convert.ToInt32((lh.position.y + y) + ((lh.position.x + x) * (terData.heightmapResolution)))]);
                    }
                }
                foreach (TerrainPathCell lH in localHeights)
                {
                    cumulativeHeights += blendLRheightmap[(int)lH.position.y, (int)lH.position.x];
                }
                blendLRheightmap[(int)(lh.position.y),
                    (int)(lh.position.x)] = (terrainHeights[(int)lh.position.y,
                        (int)lh.position.x] * (1f - blendAmount)) + (((float)cumulativeHeights / ((Mathf.Pow(((float)1f * 2f + 1f), 2f)) - 0f)) * blendAmount);
            }
        }
        terData.SetHeights(0, 0, blendLRheightmap);

        CreatePath(pathSmooth);

    }

    public void OnDrawGizmos()
    {
        if (showHandles && nodeObjectVerts != null && nodeObjectVerts.Length > 0)
        {
            int n = nodeObjectVerts.Length;
            for (int i = 0; i < n; i++)
            {
                // Handles...
                Gizmos.color = Color.white;
                Gizmos.DrawLine(transform.TransformPoint(nodeObjectVerts[i] + new Vector3(-0.5f, 0, 0)), transform.TransformPoint(nodeObjectVerts[i] + new Vector3(0.5f, 0, 0)));
                Gizmos.DrawLine(transform.TransformPoint(nodeObjectVerts[i] + new Vector3(0, -0.5f, 0)), transform.TransformPoint(nodeObjectVerts[i] + new Vector3(0, 0.5f, 0)));
                Gizmos.DrawLine(transform.TransformPoint(nodeObjectVerts[i] + new Vector3(0, 0, -0.5f)), transform.TransformPoint(nodeObjectVerts[i] + new Vector3(0, 0, 0.5f)));
            }

        }

    }

    public void TangentSolver(Mesh theMesh)
    {
        int vertexCount = theMesh.vertexCount;
        Vector3[] vertices = theMesh.vertices;
        Vector3[] normals = theMesh.normals;
        Vector2[] texcoords = theMesh.uv;
        int[] triangles = theMesh.triangles;
        int triangleCount = triangles.Length / 3;
        Vector4[] tangents = new Vector4[vertexCount];
        Vector3[] tan1 = new Vector3[vertexCount];
        Vector3[] tan2 = new Vector3[vertexCount];
        int tri = 0;
        int i1, i2, i3;
        Vector3 v1, v2, v3, w1, w2, w3, sdir, tdir;
        float x1, x2, y1, y2, z1, z2, s1, s2, t1, t2, r;
        for (int i = 0; i < (triangleCount); i++)
        {
            i1 = triangles[tri];
            i2 = triangles[tri + 1];
            i3 = triangles[tri + 2];
            v1 = vertices[i1];
            v2 = vertices[i2];
            v3 = vertices[i3];
            w1 = texcoords[i1];
            w2 = texcoords[i2];
            w3 = texcoords[i3];
            x1 = v2.x - v1.x;
            x2 = v3.x - v1.x;
            y1 = v2.y - v1.y;
            y2 = v3.y - v1.y;
            z1 = v2.z - v1.z;
            z2 = v3.z - v1.z;
            s1 = w2.x - w1.x;
            s2 = w3.x - w1.x;
            t1 = w2.y - w1.y;
            t2 = w3.y - w1.y;
            r = 1.0f / (s1 * t2 - s2 * t1);
            sdir = new Vector3((t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r);
            tdir = new Vector3((s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r, (s1 * z2 - s2 * z1) * r);
            tan1[i1] += sdir;
            tan1[i2] += sdir;
            tan1[i3] += sdir;
            tan2[i1] += tdir;
            tan2[i2] += tdir;
            tan2[i3] += tdir;
            tri += 3;
        }
        for (int i = 0; i < (vertexCount); i++)
        {
            Vector3 n = normals[i];
            Vector3 t = tan1[i];
            Vector3.OrthoNormalize(ref n, ref t);
            tangents[i].x = t.x;
            tangents[i].y = t.y;
            tangents[i].z = t.z;
            tangents[i].w = (Vector3.Dot(Vector3.Cross(n, t), tan2[i]) < 0.0f) ? -1.0f : 1.0f;
        }
        theMesh.tangents = tangents;
    }
    public Cubic[] calcNaturalCubic(int n, float[] x)
    {

        float[] gamma = new float[n + 1];
        float[] delta = new float[n + 1];
        float[] D = new float[n + 1];
        int i;
        gamma[0] = 1.0f / 2.0f;
        for (i = 1; i < n; i++)
        {
            gamma[i] = sturns / (4 - gamma[i - 1]);
        }
        gamma[n] = 1 / (2 - gamma[n - 1]);
        delta[0] = 3 * (x[1] - x[0]) * gamma[0];
        for (i = 1; i < n; i++)
        {
            delta[i] = (3 * (x[i + 1] - x[i - 1]) - delta[i - 1]) * gamma[i];
        }
        delta[n] = (3 * (x[n] - x[n - 1]) - delta[n - 1]) * gamma[n];
        D[n] = delta[n];
        for (i = n - 1; i >= 0; i--)
        {
            D[i] = delta[i] - gamma[i] * D[i + 1];
        }
        Cubic[] C = new Cubic[n + 1];
        for (i = 0; i < n; i++)
        {
            C[i] = new Cubic(
                (float)x[i], D[i],
                3 * (x[i + 1] - x[i]) - 2 * D[i] - D[i + 1],
                2 * (x[i] - x[i + 1]) + D[i] + D[i + 1]
            );
        }
        if (ring)
        {

            D[n] = (delta[0] + delta[n]) / 2;
            D[0] = (delta[0] + delta[n]) / 2;
            C[0] = new Cubic(
                   (float)x[0], D[0],
                   3 * (x[1] - x[0]) - 2 * D[0] - D[1],
                   2 * (x[0] - x[1]) + D[0] + D[1]
                   );

            C[n - 1] = new Cubic(
                     (float)x[n - 1], D[n - 1],
                     3 * (x[n] - x[n - 1]) - 2 * D[n - 1] - D[n],
                     2 * (x[n - 1] - x[n]) + D[n - 1] + D[n]
                     );
        }


        return C;
    }




}
public class Cubic
{
    float a, b, c, d;
    public Cubic(float a, float b, float c, float d)
    {
        this.a = a;
        this.b = b;
        this.c = c;
        this.d = d;
    }
    public float eval(float u)
    {
        return (((d * u) + c) * u + b) * u + a;
    }
}
