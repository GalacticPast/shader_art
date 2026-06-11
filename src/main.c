#include "raylib.h"
#include "raymath.h"

#define SCREEN_WIDTH 800
#define SCREEN_HEIGHT 600

typedef struct camera_state
{
    float   ray_origin[3];
    float   look_at[3];
    Vector2 prev_mouse_pos;
    float   yaw;
    float   pitch;
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
        .ray_origin     = {0.0, 0.0, -3.0},
        .look_at        = {0.0, 0.0, 0.0},
        .prev_mouse_pos = GetMousePosition(),
        .yaw            = 0.0,
        .pitch          = 0.0,
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

    float *yaw   = &c_state->yaw;
    float *pitch = &c_state->pitch;

    // 1. Calculate mouse delta
    Vector2 mouse_pos   = GetMousePosition();
    float   sensitivity = 0.1f;
    float   d_x         = mouse_pos.x - c_state->prev_mouse_pos.x;
    float   d_y         = mouse_pos.y - c_state->prev_mouse_pos.y;

    c_state->prev_mouse_pos = mouse_pos;

    *yaw   += d_x * sensitivity;
    *pitch += d_y * sensitivity; // Change to -= if you prefer inverted vertical look

    // FIX 1: Clamp PITCH (up/down), leave yaw alone so you can spin 360 degrees
    if (*pitch > 89.0f)
        *pitch = 89.0f;
    if (*pitch < -89.0f)
        *pitch = -89.0f;

    // FIX 2: Dereference pointers (*yaw and *pitch) inside the trig functions
    Vector3 direction;
    direction.x = cosf(DEG2RAD * *yaw) * cosf(DEG2RAD * *pitch);
    direction.y = sinf(DEG2RAD * *pitch);
    direction.z = sinf(DEG2RAD * *yaw) * cosf(DEG2RAD * *pitch);

    Vector3 forward = Vector3Normalize(direction);
    Vector3 right   = Vector3Normalize(Vector3CrossProduct(forward, world_up));

    // 2. Create a movement delta vector
    Vector3 move_delta = {0.0f, 0.0f, 0.0f};

    if (IsKeyDown(KEY_W))
        move_delta = Vector3Add(move_delta, forward);
    if (IsKeyDown(KEY_S))
        move_delta = Vector3Subtract(move_delta, forward);

    // FIX 3: Swap A and D so strafing directions are natural
    if (IsKeyDown(KEY_A))
        move_delta = Vector3Subtract(move_delta, right);
    if (IsKeyDown(KEY_D))
        move_delta = Vector3Add(move_delta, right);

    if (IsKeyDown(KEY_UP))
        move_delta = Vector3Add(move_delta, world_up);
    if (IsKeyDown(KEY_DOWN))
        move_delta = Vector3Subtract(move_delta, world_up);

    // 3. Apply position updates
    if (Vector3Length(move_delta) > 0.0f)
    {
        move_delta = Vector3Normalize(move_delta);
        move_delta = Vector3Scale(move_delta, speed);

        c_state->ray_origin[0] += move_delta.x;
        c_state->ray_origin[1] += move_delta.y;
        c_state->ray_origin[2] += move_delta.z;
    }

    c_state->look_at[0] = c_state->ray_origin[0] + forward.x;
    c_state->look_at[1] = c_state->ray_origin[1] + forward.y;
    c_state->look_at[2] = c_state->ray_origin[2] + forward.z;
}
