#include "raylib.h"
#include "raymath.h"

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
    float   speed    = 0.05f;
    Vector3 world_up = {0.0f, 1.0f, 0.0f};

    // 1. Convert float arrays into temporary Raylib Vector3s
    Vector3 orig = {c_state->ray_origin[0], c_state->ray_origin[1], c_state->ray_origin[2]};
    Vector3 look = {c_state->look_at[0], c_state->look_at[1], c_state->look_at[2]};

    // 2. Calculate the normalized FORWARD vector (target - origin)
    Vector3 forward = Vector3Subtract(look, orig);
    forward         = Vector3Normalize(forward);

    // 3. Calculate the normalized RIGHT vector (cross product of forward and world up)
    Vector3 right = Vector3CrossProduct(forward, world_up);
    right         = Vector3Normalize(right);

    // 4. Create a movement delta vector
    Vector3 move_delta = {0.0f, 0.0f, 0.0f};

    if (IsKeyDown(KEY_W))
        move_delta = Vector3Add(move_delta, forward);
    if (IsKeyDown(KEY_S))
        move_delta = Vector3Subtract(move_delta, forward);

    if (IsKeyDown(KEY_A))
        move_delta = Vector3Add(move_delta, right);
    if (IsKeyDown(KEY_D))
        move_delta = Vector3Subtract(move_delta, right);

    if (IsKeyDown(KEY_UP))
        move_delta = Vector3Add(move_delta, world_up);
    if (IsKeyDown(KEY_DOWN))
        move_delta = Vector3Subtract(move_delta, world_up);

    // 5. If we have movement input, apply it back to our state arrays
    if (Vector3Length(move_delta) > 0.0f)
    {
        // Normalize the movement direction and scale by frame speed
        move_delta = Vector3Normalize(move_delta);
        move_delta = Vector3Scale(move_delta, speed);

        // Update BOTH the ray origin and look_at target so the camera preserves its view angle
        c_state->ray_origin[0] += move_delta.x;
        c_state->ray_origin[1] += move_delta.y;
        c_state->ray_origin[2] += move_delta.z;

        c_state->look_at[0] += move_delta.x;
        c_state->look_at[1] += move_delta.y;
        c_state->look_at[2] += move_delta.z;
    }
}
