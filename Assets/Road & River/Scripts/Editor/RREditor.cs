using UnityEngine;
using UnityEditor;
using System;
using System.Collections;
using System.Collections.Generic;

[CustomEditor(typeof(RR))]

public class RREditor : Editor 
{
	public override void OnInspectorGUI() 
	{
		
        EditorGUILayout.Separator();
        EditorGUILayout.Separator();
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();
        GUILayout.Label((Texture2D)Resources.Load("Logo",typeof(Texture2D)));
        GUILayout.FlexibleSpace();
        EditorGUILayout.EndHorizontal();
		RR rr= (RR) target as RR;
		
		EditorGUILayout.Separator();
		EditorGUILayout.Separator();
		EditorGUILayout.Separator();
		Rect startButton = EditorGUILayout.BeginHorizontal();
		startButton.x = startButton.width / 2 - 100;
		startButton.width = 200;
		startButton.height = 18;
		
		if (GUI.Button(startButton, "New Path")) 
		{
          	rr.NewPath();

			GUIUtility.ExitGUI();
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
            EditorUtility.SetDirty(rr);
		}
	}
}