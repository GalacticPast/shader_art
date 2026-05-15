#include "raylib.h"
#include "stdio.h"

#define SCREEN_WIDTH 800
#define SCREEN_HEIGHT 600

int main()
{
    SetConfigFlags(FLAG_BORDERLESS_WINDOWED_MODE | FLAG_WINDOW_RESIZABLE); // Setup init configuration flags (view FLAGS)
    InitWindow(0, 0, "Raymarching Shader");
    SetTargetFPS(60);

    Shader shader = LoadShader(0, "../src/fragment.glsl");

    int width  = GetScreenWidth();
    int height = GetRenderHeight();

    // 1. Get the memory locations for BOTH uniforms
    int resolutionLoc = GetShaderLocation(shader, "u_resolution");
    int timeLoc       = GetShaderLocation(shader, "u_time"); // Get time location

    float resolution[2] = {width, height};

    long lastModTime = GetFileModTime("../src/fragment.glsl");

    while (!WindowShouldClose())
    {
        long currentModTime = GetFileModTime("../src/fragment.glsl");
        if (currentModTime > lastModTime)
        {
            shader        = LoadShader(0, "../src/fragment.glsl");
            lastModTime   = currentModTime;
            width         = GetScreenWidth();
            height        = GetRenderHeight();
            resolution[0] = width;
            resolution[1] = height;
            printf("width :%d, height: %d\n", width, height);
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
        DrawRectangle(0, 0, width, height, WHITE);
        EndShaderMode();

        EndDrawing();
    }

    UnloadShader(shader);
    CloseWindow();

    return 0;
}
