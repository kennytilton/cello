/* Building on MacOSX:
 *
 *  g++ -bundle FTGLFromC.cpp -o libfgc.dylib -I/path/to/FTGL/include/ \
 *      -I/usr/X11R6/include/ -I/usr/X11R6/include/freetype2 \
 *      -L/path/to/where/libftgl.a/is/ \
 *      -L/System/Library/Frameworks/OpenGL.framework/Libraries/ \
 *      -lftgl -lfreetype -lz -lGL -lGLU -lobjc
 */

/*
;;;
;;; Copyright � 2004 by Kenneth William Tilton.
;;;
;;; Permission is hereby granted, free of charge, to any person obtaining a copy 
;;; of this software and associated documentation files (the "Software"), to deal 
;;; in the Software without restriction, including without limitation the rights 
;;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
;;; copies of the Software, and to permit persons to whom the Software is furnished 
;;; to do so, subject to the following conditions:
;;;
;;; The above copyright notice and this permission notice shall be included in 
;;; all copies or substantial portions of the Software.
;;;
;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
;;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
;;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
;;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
;;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
;;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
;;; IN THE SOFTWARE.
*/

/* $Id */

/* ========================================================================== */
/* INCLUDES                                                                   */
/* ========================================================================== */

#include <assert.h>

#include "FTGLBitmapFont.h"
#include "FTBitmapGlyph.h"

#include "FTGLPixmapFont.h"
#include "FTPixmapGlyph.h"

#include "FTGLTextureFont.h"
#include "FTTextureGlyph.h"

#include "FTGlyphContainer.h"
#include "FTBBox.h"

#include "FTGLPolygonFont.h"
#include "FTPolyGlyph.h"

#include "FTGLOutlineFont.h"
#include "FTOutlineGlyph.h"

#include "FTGLExtrdFont.h"
#include "FTExtrdGlyph.h"

/* We only need __stdcall for Windows */

#if !defined(WINDOWS)
#define __stdcall
#endif

/* ========================================================================== */
/* INTERFACE FUNCTIONS                                                        */
/* ========================================================================== */

extern "C" {

  /*
void __stdcall fgcBuildGlyphs( FTFont* f ) 
{
  f->BuildGlyphs();
}
  */

bool __stdcall fgcSetFaceSize( FTFont* f,
                               unsigned int faceSize, 
                               unsigned int res ) 
{
  return f->FaceSize( faceSize, res );
}

float __stdcall fgcAscender( FTFont* f ) 
{
  return f->Ascender();
}

float __stdcall fgcDescender( FTFont* f ) 
{
  return f->Descender();
}

float __stdcall fgcStringAdvance( FTFont* f, const char* string ) 
{
  return f->Advance( string );
}


  /*
int __stdcall fgcCharTexture( FTFont* f, int chr ) 
{
  return ((FTGlyph *) f->MakeGlyph( chr ))->glRendering();
  //return f->GlyphRendering( chr );
}
  */

/*
void FTFont::DoRender( const unsigned int chr, const unsigned int nextChr)
{
    CheckGlyph( chr);

    FTPoint kernAdvance = glyphList->Render( chr, nextChr, pen);
    
    pen.x += kernAdvance.x;
    pen.y += kernAdvance.y;
}*/



float __stdcall fgcStringX( FTFont* f, const char* string ) 
{
  float llx,lly,llz,urx,ury,urz;

  f->BBox( string, llx, lly, llz, urx, ury, urz );
  return llx;
}

void __stdcall fgcRender( FTFont* f, const char *string )
{
  f->Render( string );
}

void __stdcall fgcFree( FTFont* f ) 
{
  delete f;
}

//--------- Bitmap ----------------------------------------------

FTGLBitmapFont* __stdcall fgcBitmapMake( const char* fontname ) 
{
  return new FTGLBitmapFont( fontname );
}

//--------- Pixmap ----------------------------------------------

FTGLPixmapFont* __stdcall fgcPixmapMake( const char* fontname ) 
{
  return new FTGLPixmapFont( fontname );
}

//--------- Texture ----------------------------------------------

FTGLTextureFont* __stdcall fgcTextureMake( const char* fontname ) 
{
  return new FTGLTextureFont( fontname );
}

//--------- Polygon ----------------------------------------------

FTGLPolygonFont* __stdcall fgcPolygonMake( const char* fontname ) 
{
  return new FTGLPolygonFont( fontname );
}

//--------- Outline ----------------------------------------------

FTGLOutlineFont* __stdcall fgcOutlineMake( const char* fontname ) 
{
  return new FTGLOutlineFont( fontname );
}

//--------- Extruded Polygon -------------------------------------

FTGLExtrdFont* __stdcall fgcExtrudedMake( const char* fontname ) 
{
  return new FTGLExtrdFont( fontname );
}


bool __stdcall fgcSetFaceDepth( FTGLExtrdFont* f, float depth ) 
{
  f->Depth( depth );
  return true;
}

} // extern "C" 
 
