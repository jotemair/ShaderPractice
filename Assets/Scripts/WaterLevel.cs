using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
[AddComponentMenu("Image Effects/Water Level")]
public class WaterLevel : MonoBehaviour
{
    #region Public Properties

    #endregion

    #region Private Variables

    [SerializeField]
    Shader _shader = null;

    Material _material = null;

    [SerializeField]
    private Texture2D _water = null;

    private Camera _cam = null;

    [SerializeField]
    private float _waterLevel = 10f;

    [SerializeField]
    [Range(0f, 360f)]
    private float _waterDirection = 37f;

    [SerializeField]
    [Range(0f, 20f)]
    private float _waterSpeed = 5f;

    [SerializeField]
    private Color _waterTint = Color.white;

    [SerializeField]
    private Texture2D _noise = null;

    [SerializeField]
    [Range(0f, 360f)]
    private float _noiseDirection = 17f;

    [SerializeField]
    [Range(0f, 20f)]
    private float _noiseSpeed = 7f;

    [SerializeField]
    [Range(0f, 2f)]
    private float _noiseStrength = 0.35f;

    #endregion

    #region MonoBehaviour functions

    private void Start()
    {
        // Initial Variable setup
        _cam = GetComponent<Camera>();

        // We'll be using depth values to calculate world position, so we need to be in Depth or DepthNormals mode
        _cam.depthTextureMode = DepthTextureMode.Depth;

        if (null == _water)
        {
            _water = new Texture2D(1, 1);
        }

        if (null == _noise)
        {
            _noise = new Texture2D(1, 1);
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // If we have a shader set use it, otherwise just blit the image without change
        if (null != _shader)
        {
            // If we don't have a material yet, make a temporary one from the shader
            if (null == _material)
            {
                _material = new Material(_shader);
                _material.hideFlags = HideFlags.DontSave;
            }

            // Calculate and set values needed to get world position from depth values
            {
                // The world position of the (0, 0) corner of the far clip plane
                Vector3 screen_Corner;

                // The vector that goes from the world position of the (0, 0) corner to the world position of the (width, 0) corner of the far clip plane
                Vector3 x_Vector;

                // The vector that goes from the world position of the (0, 0) corner to the world position of the (0, height) corner of the far clip plane
                Vector3 y_Vector;

                // Rays that goes to one of three corners or the center of the far clip plane
                Ray ray_x = _cam.ScreenPointToRay(new Vector3(Screen.width, 0));
                Ray ray_y = _cam.ScreenPointToRay(new Vector3(0, Screen.height));
                Ray ray_0 = _cam.ScreenPointToRay(new Vector3(0, 0));
                Ray ray_2 = _cam.ScreenPointToRay(new Vector3(Screen.width / 2, Screen.height / 2));

                // Get the angle between the center of the far clip plane and the (0, 0) corner in radian
                float angleRad = (Mathf.PI * Vector3.Angle(ray_0.direction, ray_2.direction)) / 180f;

                // Calculate the distance of the far clip plane corner based on the center distance and the angle
                float cornerDistance = _cam.farClipPlane / Mathf.Cos(angleRad);

                // Calculate the screen vectors
                screen_Corner = transform.position + cornerDistance * ray_0.direction;
                x_Vector = cornerDistance * ray_x.direction - cornerDistance * ray_0.direction;
                y_Vector = cornerDistance * ray_y.direction - cornerDistance * ray_0.direction;

                // Debug draw to show the x_Vector and y_Vector on the far clip plane
                // Debug.DrawRay(screen_Corner, x_Vector, Color.red);
                // Debug.DrawRay(screen_Corner, y_Vector, Color.green);

                // Set the screen vectors
                _material.SetVector("_Vector_X", new Vector4(x_Vector.x, x_Vector.y, x_Vector.z, 0));
                _material.SetVector("_Vector_Y", new Vector4(y_Vector.x, y_Vector.y, y_Vector.z, 0));
                _material.SetVector("_Screen_Corner", new Vector4(screen_Corner.x, screen_Corner.y, screen_Corner.z, 0));
            }

            // Set other properties related to the water texture
            _material.SetTexture("_WaterTexture", _water);
            _material.SetFloat("_WaterLevel", _waterLevel);
            Vector3 waterDir = Quaternion.Euler(0f, _waterDirection, 0f) * Vector3.forward;
            _material.SetVector("_WaterDirection", new Vector4(waterDir.x, waterDir.z, _waterSpeed, 0f));
            _material.SetColor("_ColorTint", _waterTint);

            // Set noise map properties
            _material.SetTexture("_NoiseMap", _noise);
            Vector3 noiseDir = Quaternion.Euler(0f, _noiseDirection, 0f) * Vector3.forward;
            _material.SetVector("_NoiseDirection", new Vector4(noiseDir.x, noiseDir.z, _noiseSpeed, _noiseStrength));

            Graphics.Blit(source, destination, _material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

    #endregion
}
