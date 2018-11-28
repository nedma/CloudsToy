using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

public class GenerateNoiseOctavesWizard : ScriptableWizard {

    public int width = 512;
    public int height = 512;
    public Vector3 sunDirection = new Vector3(1.0f, 1.0f, -2.0f);
	
    void OnWizardUpdate () {
        helpString = "Generate for noise octaves for 2D dynamic clouds simulation.";
        isValid = (width > 0) && (height > 0);
    }

    void OnWizardCreate () {
        _GenerateNoiseOctaves();
    }

    [MenuItem("Clouds/Generate Octaves")]
    static void GenerateNoiseOctaves () {
        ScriptableWizard.DisplayWizard<GenerateNoiseOctavesWizard>("Generate Octaves", "Generate");
    }

    private void _GenerateNoiseOctaves() {
        Color[] pixelsForOctaves = new Color[width * height * 4];

        Vector3 sunDir = sunDirection.normalized;

        Vector2[] displacements = new Vector2[3];
        displacements[0] = new Vector2(Mathf.Floor(sunDir.x * 10.0f), Mathf.Floor(sunDir.z * 10.0f));
        displacements[1] = displacements[0] * 2.0f;
        displacements[2] = displacements[0] * 3.0f;

        for(int i = 0; i < height; i++) {
            for(int j = 0; j < width; j++) {
                float scale = 2.0f;
                float noise = 0.0f;
                float[] noiseDisplaced = new float[3];
                for (int o = 0; o < 4; o++) {
                    // The real noise
                    noise = SimplexNoise.SeamlessNoise((float)j/width, (float)i/height, scale, scale, 20.0f);
                    noise = noise * 0.5f + 0.5f;

                    for (int s = 0; s < 3; s++) {
                        float yDisplaced = ((float)i + displacements[s].y)/height;
                        float xDisplaced = ((float)j + displacements[s].x)/width;
                        while (xDisplaced > 1.0f) {
                            xDisplaced = xDisplaced - 1.0f;
                        }
                        while (yDisplaced > 1.0f) {
                            yDisplaced = yDisplaced - 1.0f;
                        }
                        while (xDisplaced < 0.0f) {
                            xDisplaced = xDisplaced + 1.0f;
                        }
                        while (yDisplaced < 0.0f) {
                            yDisplaced = yDisplaced + 1.0f;
                        }
                        noiseDisplaced[s] = SimplexNoise.SeamlessNoise(xDisplaced, yDisplaced, scale, scale, 20.0f);
                        noiseDisplaced[s] = noiseDisplaced[s] * 0.5f + 0.5f;
                    }

                    pixelsForOctaves[width * height * o + i * width + j] = new Color(noise, noiseDisplaced[0], noiseDisplaced[1], noiseDisplaced[2]);
                    scale *= 2.0f;
                }
            }
        }

        List<Color> pixels = new List<Color>(pixelsForOctaves);
        for (int o = 0; o < 4; o++) {
            Texture2D octave = new Texture2D(width, height, TextureFormat.ARGB32, false, true);
            octave.filterMode = FilterMode.Bilinear;
            octave.wrapMode = TextureWrapMode.Repeat;
            octave.SetPixels(pixels.GetRange(width * height * o, width * height).ToArray());
            octave.Apply();

            byte[] bytes = octave.EncodeToPNG();
            System.IO.File.WriteAllBytes(Application.dataPath + "/2DDynamicClouds/Textures/Octave" + o.ToString() + ".png", bytes);
        }
    }
}
