#include "raylib.h"

#define SCREEN_WIDTH 800
#define SCREEN_HEIGHT 600

int main()
{
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Raymarching Shader");
    SetTargetFPS(60);

    Shader shader = LoadShader(0, "../src/fragment.glsl");

    // 1. Get the memory locations for BOTH uniforms
    int resolutionLoc = GetShaderLocation(shader, "u_resolution");
    int timeLoc       = GetShaderLocation(shader, "u_time"); // Get time location

    float resolution[2] = {(float)SCREEN_WIDTH, (float)SCREEN_HEIGHT};

    long lastModTime = GetFileModTime("../src/fragment.glsl");

    while (!WindowShouldClose())
    {
        long currentModTime = GetFileModTime("../src/fragment.glsl");
        if (currentModTime > lastModTime)
        {
            shader      = LoadShader(0, "../src/fragment.glsl");
            lastModTime = currentModTime;
        }

        // 2. Get the current time in seconds since the window opened
        float time = (float)GetTime();

        // 3. Send both resolution AND time to the shader every frame
        SetShaderValue(shader, resolutionLoc, resolution, SHADER_UNIFORM_VEC2);
        SetShaderValue(shader, timeLoc, &time, SHADER_UNIFORM_FLOAT); // Send time

        BeginDrawing();
        ClearBackground(RAYWHITE);

        BeginShaderMode(shader);
        // Draw a full-screen rectangle for the shader to render onto
        DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, WHITE);
        EndShaderMode();

        EndDrawing();
    }

    UnloadShader(shader);
    CloseWindow();

    return 0;
}
