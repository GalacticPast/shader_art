#include "raylib.h"
#include "stdio.h"

#define SCREEN_WIDTH 800
#define SCREEN_HEIGHT 600

typedef struct camera_state
{
    float   ray_origin[3];
    float   look_at[3];
    Vector2 p_c_p;
} camera_state;

void set_camera_pos(camera_state *state);

int main()
{
    SetConfigFlags(FLAG_WINDOW_RESIZABLE); // Setup init configuration flags (view FLAGS)
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Raymarching Shader");
    SetTargetFPS(60);

    Shader shader = LoadShader(0, "../src/fragment.glsl");

    int width  = GetScreenWidth();
    int height = GetRenderHeight();

    // 1. Get the memory locations for BOTH uniforms
    int resolution_loc = GetShaderLocation(shader, "u_resolution");
    int time_loc       = GetShaderLocation(shader, "u_time"); // Get time location
    int ray_origin_loc = GetShaderLocation(shader, "ray_origin");
    int look_at_loc    = GetShaderLocation(shader, "look_at_dir"); // Get time location

    float resolution[2] = {width, height};

    struct camera_state c_state = {
        .ray_origin = {0.0, 0.0, -3.0},
        .look_at    = {0.0, 0.0, 0.0},
        .p_c_p      = {0.0, 0.0},
    };

    long lastModTime
        = GetFileModTime("../src/fragment.glsl");

    while (!WindowShouldClose())
    {
        long currentModTime = GetFileModTime("../src/fragment.glsl");
        if (currentModTime > lastModTime)
        {
            Shader temp = LoadShader(0, "../src/fragment.glsl");
            if (IsShaderValid(temp))
            {
                shader = temp;
            }
            lastModTime   = currentModTime;
            width         = GetScreenWidth();
            height        = GetRenderHeight();
            resolution[0] = width;
            resolution[1] = height;
        }
        set_camera_pos(&c_state);
        // 2. Get the current time in seconds since the window opened
        float time = (float)GetTime();

        // 3. Send both resolution AND time to the shader every frame
        SetShaderValue(shader, ray_origin_loc, c_state.ray_origin, SHADER_UNIFORM_VEC3);
        SetShaderValue(shader, look_at_loc, c_state.look_at, SHADER_UNIFORM_VEC3);
        SetShaderValue(shader, time_loc, &time, SHADER_UNIFORM_FLOAT);           // Send time
        SetShaderValue(shader, resolution_loc, resolution, SHADER_UNIFORM_VEC2); // Send time

        BeginDrawing();
        ClearBackground(RAYWHITE);

        BeginShaderMode(shader);
        DrawRectangle(0, 0, width, height, WHITE);
        EndShaderMode();

        EndDrawing();
    }

    UnloadShader(shader);
    CloseWindow();

    return 0;
}

void set_camera_pos(camera_state *c_state)
{
    float *r_o   = c_state->ray_origin;
    float *l_a   = c_state->look_at;
    float  speed = 0.05;

    if (IsKeyDown(KEY_W))
    {
        r_o[2] += speed;
    }
    if (IsKeyDown(KEY_S))
    {
        r_o[2] -= speed;
    }
    if (IsKeyDown(KEY_A))
    {
        r_o[0] -= speed;
    }
    if (IsKeyDown(KEY_D))
    {
        r_o[0] += speed;
    }
    if (IsKeyDown(KEY_UP))
    {
        r_o[1] += speed;
    }
    if (IsKeyDown(KEY_DOWN))
    {
        r_o[1] -= speed;
    }
    if (IsKeyDown(KEY_LEFT))
    {
        l_a[1] -= 0.009;
    }
    if (IsKeyDown(KEY_RIGHT))
    {
        l_a[1] += 0.009;
    }
}
