using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
[AddComponentMenu("Image Effects/Drawing Paper")]
public class DrawingPaper : MonoBehaviour
{
    #region Variables

    public Shader shader = null;
    private float timeX = 1;
    public Color pencilColor = new Color(0, 0, 0, 0);

    [Range(0, 2)]
    public float pencilSize = 0.00125f;

    [Range(0, 2)]
    public float pencilCorrection = 0.35f;

    [Range(0, 1)]
    public float intensity = 1f;

    [Range(0, 2)]
    public float animationSpeed = 1;

    [Range(0, 1)]
    public float cornerLoss = 1f;

    [Range(0, 1)]
    public float paperFadeIn = 0f;

    [Range(0, 1)]
    public float paperFadeColor = 1f;

    public Color backColor = new Color(1, 1, 1, 1);
    private Material paperMaterial = null;
    public Texture2D paper = null;

    #endregion

    #region Properties

    Material material
    {
        get
        {
            if (null == paperMaterial)
            {
                paperMaterial = new Material(shader);
                paper.hideFlags = HideFlags.HideAndDontSave;
            }

            return paperMaterial;
        }
    }

    #endregion

    private void Start()
    {
        if (!SystemInfo.supportsImageEffects)
        {
            enabled = false;
        }
    }

    private void OnDisable()
    {
        if (null != paperMaterial)
        {
            DestroyImmediate(paperMaterial);
            paperMaterial = null;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (null != shader)
        {
            timeX += Time.deltaTime;
            if (timeX > 100f)
            {
                timeX = 0f;
            }

            material.SetFloat("_TimeX", timeX);

            material.SetColor("_PencilColor", pencilColor);
            material.SetColor("_BackColor", backColor);

            material.SetFloat("_PencilSize", pencilSize);
            material.SetFloat("_PencilCorrection", pencilCorrection);
            material.SetFloat("_Intesity", intensity);
            material.SetFloat("_AnimationSpeed", animationSpeed);
            material.SetFloat("_CornerLoss", cornerLoss);
            material.SetFloat("_PaperFadeIn", paperFadeIn);
            material.SetFloat("_PaperFadeColor", paperFadeColor);

            material.SetTexture("_PaperTexture", paper);

            Graphics.Blit(source, destination, material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
