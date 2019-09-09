using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
[AddComponentMenu("Image Effects/Analogue Glitch")]
public class AnalogueGlitch : MonoBehaviour
{
    #region Public Properties
    // Scan Line Jitter
    [SerializeField, Range(0, 1)]
    private float _scanLineJitter = 0f;

    public float ScanLineJitter
    {
        get { return _scanLineJitter; }
        set { _scanLineJitter = value; }
    }

    // Vertical Jump
    [SerializeField, Range(0, 1)]
    private float _verticalJump = 0f;

    public float VerticalJump
    {
        get { return _verticalJump; }
        set { _verticalJump = value; }
    }

    // Horizontal Shake
    [SerializeField, Range(0, 1)]
    private float _horizontalShake = 0f;

    public float HorizontalShake
    {
        get { return _horizontalShake; }
        set { _horizontalShake = value; }
    }

    // Color Drift
    [SerializeField, Range(0, 1)]
    private float _colorDrift = 0f;

    public float ColorDrift
    {
        get { return _colorDrift; }
        set { _colorDrift = value; }
    }

    #endregion

    #region Private Variables

    [SerializeField]
    Shader _shader = null;

    Material _material = null;

    float _verticalJumpTime = 0f;

    #endregion

    #region MonoBehaviour functions

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (null == _material)
        {
            _material = new Material(_shader);
            _material.hideFlags = HideFlags.DontSave;
        }

        float sl_thresh = Mathf.Clamp01(1f - _scanLineJitter * 1.2f);
        float sl_disp = 0.002f + Mathf.Pow(_scanLineJitter, 3f) * 0.05f;
        _material.SetVector("_ScanLineJitter", new Vector2(sl_disp, sl_thresh));

        _verticalJumpTime += Time.deltaTime * _verticalJump * 11.3f;
        _material.SetVector("_VerticalJump", new Vector2(_verticalJump, _verticalJumpTime));

        _material.SetFloat("_HorizontalShake", _horizontalShake * 0.2f);

        _material.SetVector("_ColorDrift", new Vector2(_colorDrift * 0.04f, Time.time * 606.11f));

        Graphics.Blit(source, destination, _material);
    }

    #endregion
}
