using UnityEngine;
using UnityEditor;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

[CustomEditor(typeof(RRAttached))]
[CanEditMultipleObjects]
public class RRAttachedEditor : Editor
{
    private object row;

    public void OnSceneGUI()
    {
        RRAttached RR = (RRAttached)target as RRAttached;
        Event currentEvent = Event.current;


        if (RR.addNodeMode == true)
        {
            if (Event.current.shift)
            {
                if (Event.current.type == EventType.MouseDown)
                {
                    if (Event.current.button == 1)
                    {
                        Vector3 pathNode = GetTerrainCollisionInEditor(currentEvent);

                        TerrainPathCell pathNodeCell = new TerrainPathCell();
                        pathNodeCell.position.x = pathNode.x;
                        pathNodeCell.position.y = pathNode.z;
                        pathNodeCell.heightAtCell = pathNode.y;

                        RR.CreatePathNode(pathNodeCell);
                    }
                }
            }
        }
        if (Event.current.control && !Event.current.alt && !Event.current.shift)
        {
            RR.CreatePath(RR.pathSmooth);
        }
            if (!Event.current.shift && Event.current.alt)
            {
           
            if (Event.current.type == EventType.MouseDown)
            {
                if (Event.current.button == 1)
                {
                    Vector3 pathNode = GetCollisionInEditor(currentEvent);
                    RR.Deletepoint(pathNode);
                }
            }
        }


        if (Event.current.shift && !Event.current.alt && !RR.addNodeMode)
        {
            if (Event.current.type == EventType.MouseDown)
            {
                if (Event.current.button == 1)
                {
                    Vector3 pathNode = GetTerrainCollisionInEditor(currentEvent);

                    TerrainPathCell pathNodeCell = new TerrainPathCell();
                    pathNodeCell.position.x = pathNode.x;
                    pathNodeCell.position.y = pathNode.z;
                    pathNodeCell.heightAtCell = pathNode.y;

                    RR.Addpoint(pathNodeCell);
                }
            }
        }



        if (Event.current.type == EventType.MouseDown)
        {
            if (Event.current.button == 0)
            {
                RR.addNodeMode = false;
              
            }
        }
        if (RR.nodeObjects != null && RR.nodeObjects.Count != 0)
        {
            Quaternion rot = Quaternion.identity;
            int n = RR.nodeObjects.Count;
            PathNodeObjects node = null;
            for (int i = 0; i < n; i++)
            {
                node = RR.nodeObjects[i];
                if (RR.ring)
                {
                    if (i > 0)
                    {
                        node.position = Handles.PositionHandle(node.position, Quaternion.identity);
                        if (RR.roadSlopes)
                            node.rotation = Handles.RotationHandle(node.rotation, node.position);
                    }

                }
                else
                {
                    node.position = Handles.PositionHandle(node.position, Quaternion.identity);
                    if (RR.roadSlopes)
                        node.rotation = Handles.RotationHandle(node.rotation, node.position);
                }
            }
           // Undo.RecordObject(RR, "Road_edit");
           
        }
        EditorUtility.SetDirty(RR);
        if (GUI.changed)
        {
            if ((RR.isRoad) && (RR.isFinalized == false))
                RR.CreatePath(RR.pathSmooth);

            else if (RR.isFinalized)
                RR.CreatePath(RR.pathSmooth);
        }




    }
    public override void OnInspectorGUI()
    {

        EditorGUILayout.Separator();
        EditorGUILayout.Separator();
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();
        GUILayout.Label((Texture2D)Resources.Load("Logo", typeof(Texture2D)));
        GUILayout.FlexibleSpace();
        EditorGUILayout.EndHorizontal();
        RRAttached RR = (RRAttached)target as RRAttached;


        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.PrefixLabel("Ring");
        EditorGUILayout.Separator();
        RR.ring = EditorGUILayout.Toggle(RR.ring);
        EditorGUILayout.EndHorizontal();


        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.PrefixLabel("Show handles");
        EditorGUILayout.Separator();
        RR.showHandles = EditorGUILayout.Toggle(RR.showHandles);
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.PrefixLabel("Align to Terrain");
        EditorGUILayout.Separator();
        RR.alignToTerrain = EditorGUILayout.Toggle(RR.alignToTerrain);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.PrefixLabel("Road Slopes");
        EditorGUILayout.Separator();
        RR.roadSlopes = EditorGUILayout.Toggle(RR.roadSlopes);
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.PrefixLabel("Align terrain to path");
        EditorGUILayout.Separator();
        RR.alignTerrainToRoad = EditorGUILayout.Toggle(RR.alignTerrainToRoad);
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Separator(); EditorGUILayout.Separator();
        EditorGUILayout.Separator();

        RR.terrainDepth = EditorGUILayout.Slider("Terrain Depth", RR.terrainDepth, 0, 10);
        RR.terrainWidth = EditorGUILayout.Slider("Terrain Width", RR.terrainWidth, 0, 10);
        EditorGUILayout.Separator(); EditorGUILayout.Separator();
        EditorGUILayout.Separator();
        RR.pathWidth = EditorGUILayout.Slider("Path Width", RR.pathWidth, 1, 20);
        RR.pathSmooth = EditorGUILayout.IntSlider("Mesh Smoothing", RR.pathSmooth, 1, 60);
        RR.sturns = EditorGUILayout.Slider("Smooth turns", RR.sturns, 0, 2);




        RR.index = EditorGUILayout.IntSlider("Index", RR.index, 0, 60);
        RR.UV = EditorGUILayout.Slider("UV", RR.UV, 0.5f, 30);





        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.PrefixLabel("Enable Texturing");
        RR.enableTexturing = EditorGUILayout.Toggle(RR.enableTexturing);
        EditorGUILayout.EndHorizontal();
        if (RR.enableTexturing)
        {
            EditorGUILayout.Separator(); EditorGUILayout.Separator();
            EditorGUILayout.Separator();
            RR.pathTexture = EditorGUILayout.IntSlider("Texture Prototype", RR.pathTexture, 0, 30);
            RR.TexturesWidth = EditorGUILayout.Slider("Texture Width", RR.TexturesWidth, 1, 30);
            //RR.pathWear = EditorGUILayout.Slider("Wear", RR.pathWear, 0.5f, 1.0f);
        }



        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.PrefixLabel("Vegetation");
        RR.enableVegetation = EditorGUILayout.Toggle(RR.enableVegetation);
        EditorGUILayout.EndHorizontal();
        if (RR.enableVegetation)
        {
            EditorGUILayout.Separator(); EditorGUILayout.Separator();
            EditorGUILayout.Separator();
            RR.detailRemoveWidth = EditorGUILayout.Slider("Detail Remove Width", RR.detailRemoveWidth, 1, 30);
            RR.treeRemoveWidth = EditorGUILayout.Slider("Tree Remove Width", RR.treeRemoveWidth, 1, 30);
        }

        EditorGUILayout.Separator();
        EditorGUILayout.Separator();





        Rect startButton = EditorGUILayout.BeginHorizontal();
        startButton.x = startButton.width / 2 - 100;
        startButton.width = 200;
        startButton.height = 18;

        if (GUI.Button(startButton, "Add path node"))
        {
            RR.addNodeMode = true;

            GUIUtility.ExitGUI();
        }


        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Separator();

        EditorGUILayout.Separator();
        EditorGUILayout.Separator();
        EditorGUILayout.Separator();

        Rect endButton = EditorGUILayout.BeginHorizontal();
        endButton.x = endButton.width / 2 - 100;
        endButton.width = 200;
        endButton.height = 18;

        if (GUI.Button(endButton, "Generate Path"))
        {
            if (RR.nodeObjects.Count > 1)
            {
                RR.terrainCells = new TerrainPathCell[RR.terData.heightmapResolution * RR.terData.heightmapResolution];

                for (int x = 0; x < RR.terData.heightmapResolution; x++)
                {
                    for (int y = 0; y < RR.terData.heightmapResolution; y++)
                    {
                        RR.terrainCells[(y) + (x * RR.terData.heightmapResolution)].position.y = y;
                        RR.terrainCells[(y) + (x * RR.terData.heightmapResolution)].position.x = x;
                        RR.terrainCells[(y) + (x * RR.terData.heightmapResolution)].heightAtCell = RR.terrainHeights[y, x];
                        RR.terrainCells[(y) + (x * RR.terData.heightmapResolution)].isAdded = false;
                    }
                }
                RR.FinalizePath();
                RR.CreatePath(30);
                RR.isFinalized = true;
            }
            else
                Debug.Log("Not enough nodes to finalize");
        }
        EditorGUILayout.Separator();
        EditorGUILayout.Separator();
        EditorGUILayout.Separator();
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Separator();
        EditorGUILayout.Separator();
        EditorGUILayout.Separator();
        if (GUI.changed)
        {
            EditorUtility.SetDirty(RR);
            if ((RR.isRoad) && (!RR.isFinalized))
                RR.CreatePath(RR.pathSmooth);

            else if (RR.isRoad && RR.isFinalized)
                RR.CreatePath(RR.pathSmooth);
        }
    }


    public Vector3 GetTerrainCollisionInEditor(Event currentEvent)
    {
        Vector3 returnCollision = new Vector3();

        RRAttached RR = (RRAttached)target as RRAttached;

        Camera SceneCameraReceptor = new Camera();

        GameObject terrain = RR.parentTerrain;
        Terrain terComponent = (Terrain)terrain.GetComponent(typeof(Terrain));
        TerrainCollider terCollider = (TerrainCollider)terrain.GetComponent(typeof(TerrainCollider));
        TerrainData terData = terComponent.terrainData;

        if (Camera.current != null)
        {
            SceneCameraReceptor = Camera.current;

            RaycastHit raycastHit = new RaycastHit();

            Vector2 newMousePosition = new Vector2(currentEvent.mousePosition.x, Screen.height - (currentEvent.mousePosition.y + 25));

            Ray terrainRay = SceneCameraReceptor.ScreenPointToRay(newMousePosition);

            if (terCollider.Raycast(terrainRay, out raycastHit, Mathf.Infinity))
            {
                returnCollision = raycastHit.point;

                returnCollision.x = Mathf.RoundToInt((returnCollision.x / terData.size.x) * terData.heightmapResolution);
                returnCollision.y = returnCollision.y / terData.size.y;
                returnCollision.z = Mathf.RoundToInt((returnCollision.z / terData.size.z) * terData.heightmapResolution);
            }
            else
                Debug.LogError("Error: No collision with terrain to create node");

        }

        return returnCollision;
    }




    public Vector3 GetCollisionInEditor(Event currentEvent)
    {
        Vector3 returnCollision = new Vector3();
        RaycastHit hit;
        if (Camera.current != null)
        {
            Ray ray = HandleUtility.GUIPointToWorldRay(Event.current.mousePosition);
            if (Physics.Raycast(ray, out hit, Mathf.Infinity))
            {
                returnCollision = hit.point;
            }
            else
                Debug.LogError("Error: No collision with terrain to create node");
        }
        return returnCollision;
    }

}
