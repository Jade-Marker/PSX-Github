#include <sys/types.h>
#include <stdio.h>
#include <libetc.h>
#include <libgte.h>
#include <libgpu.h>
#include <stdbool.h>
#include "Fixed.h"

void InitGraphics();
void Display();
void Draw();
void SimpleTri();
void RotatingTri();

DISPENV disp[2];
DRAWENV draw[2];
int db;

#define OTLEN 2048
ulong ot[2][OTLEN];

char primitiveBuffer[2][32768*2];
char* nextPrimitive;

int rotY = 0;

int main()
{
    InitGraphics();

    while(1)
    {
        ClearOTagR(ot[db], OTLEN);

        Draw();

        Display();

        rotY += fixed(0.005);
    }

    return 0;
}

void InitGraphics()
{
    ResetGraph(0);  //Reset GPU and enable interrupts

    //Configures the pair on DISPENVS for 320x256 mode (PAL)
    SetDefDispEnv(&disp[0], 0, 0, 320, 256);
    SetDefDispEnv(&disp[1], 320, 0, 320, 256);

    //Screen offset to center the picture vertically
    disp[0].screen.y = 24;
    disp[1].screen.y = disp[0].screen.y;

    //Forces PAL video standard
    SetVideoMode(MODE_PAL);

    //Configures the pair of DRAWENVs for the DISPENVs
    SetDefDrawEnv(&draw[0], 320, 0, 320, 256);
    SetDefDrawEnv(&draw[1], 0, 0, 320, 256);

    //Specifies the clear color of the DRAWENV
    setRGB0(&draw[0], 107, 52, 235);
    setRGB0(&draw[1], 107, 52, 235);
    //Enable background clear
    draw[0].isbg = 1;
    draw[1].isbg = 1;

    //Make sure db starts with zero
    db = 0;

    nextPrimitive = primitiveBuffer[0]; //Set initial primitive pointer address

    InitGeom();

    SetGeomOffset(320/2, 256/2);
    SetGeomScreen(320/2);
  
    //Enable display
    SetDispMask(1);

    //Apply environments
    PutDispEnv(&disp[0]);
    PutDrawEnv(&draw[0]);
}

void Display()
{
    //Wait for GPU to finish drawing and V-blank
    DrawSync(0);
    VSync(0);

    PutDispEnv(&disp[db]);
    PutDrawEnv(&draw[db]);

    DrawOTag(&ot[db][OTLEN-1]);

    //Flip buffer counter
    db = !db;
    
    nextPrimitive = primitiveBuffer[db];        //reset primitive buffer pointer
}

void Draw()
{
    SimpleTri();
    RotatingTri();
}

void SimpleTri()
{
    POLY_F3* triangle = (POLY_F3*)nextPrimitive;
    SetPolyF3(triangle);

    setRGB0(triangle, 0,0,255);

    setXY3(triangle,
    32, 32,
    32-16, 32+16,
    32+16, 32+16);

    addPrim(&ot[db][0], triangle);

    nextPrimitive+= sizeof(POLY_F3);
}

void RotatingTri()
{
    SVECTOR positions[3] = {
        0, 0, 0,
        -16, 16, 32,
        +16, 16, 32
    };
    SVECTOR currentPoints[3];

    POLY_F3* triangle = (POLY_F3*)nextPrimitive;
    SetPolyF3(triangle);

    setRGB0(triangle, 255,0,255);

    MATRIX matrix = {0};
    VECTOR position = {0, 0, 0};
    SVECTOR rotation = {0, rotY, 0};
    VECTOR scale = {fixed(1.0), fixed(1.0), fixed(2.0)};

    RotMatrix(&rotation, &matrix);
    TransMatrix(&matrix, &position);
    ScaleMatrix(&matrix, &scale);
    SetTransMatrix(&matrix);
    SetRotMatrix(&matrix);

    long p; long flag; u32 z;
    z  = RotTransPers(&positions[0], (long*)&currentPoints[0], &p, &flag);
    z += RotTransPers(&positions[1], (long*)&currentPoints[1], &p, &flag);
    z += RotTransPers(&positions[2], (long*)&currentPoints[2], &p, &flag);
        
    z/= 3;

    setXY3(triangle, 
    currentPoints[0].vx, currentPoints[0].vy, 
    currentPoints[1].vx, currentPoints[1].vy, 
    currentPoints[2].vx, currentPoints[2].vy);

    if(z >= 0 && z < OTLEN)
        addPrim(&ot[db][z], triangle);

    nextPrimitive+= sizeof(POLY_F3);
}