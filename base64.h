/*

    Slightly altered base64 part, derived from William Sherif, original notice
    below.
    Altered by: Thomas Lamprecht <t.lamprecht@proxmox.com>

  Original Notice:

  https://github.com/superwills/NibbleAndAHalf
  base64explained.h -- Fast base64 encoding and decoding.
  version 1.0.0, April 17, 2013 143a

  EXPLAINS how the functions in base64.h work. You don't need this file,
  only base64.h is needed.
  Copyright (C) 2013 William Sherif
  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.
  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:
  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
  William Sherif
  will.sherif@gmail.com
  YWxsIHlvdXIgYmFzZSBhcmUgYmVsb25nIHRvIHVz
*/

const static char* b64="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
// Converts binary data of length=len to base64 characters.
char* base64( const void* binaryData, int len)
{
    const unsigned char *bin = (const unsigned char*) binaryData;

    int modulusLen = len % 3;
    // 2 gives 1 and 1 gives 2, but 0 gives 0, padding
    int pad = ((modulusLen & 1) << 1) + ((modulusLen & 2) >> 1);

    int res_len = 4 * (len + pad) / 3;
    char *res = (char *) malloc(res_len + 1); // and one for the null
    if (!res) return 0; // really shouldn't happen on Linux

    int byteNo; // needed for padding after the loop
    int rc = 0; // result counter
    for (byteNo = 0; byteNo <= len - 3; byteNo += 3) {
        unsigned char BYTE0 = bin[byteNo + 0];
        unsigned char BYTE1 = bin[byteNo + 1];
        unsigned char BYTE2 = bin[byteNo + 2];
        res[rc++] = b64[BYTE0 >> 2];
        res[rc++] = b64[((0x3 & BYTE0)<<4) + (BYTE1 >> 4)];
        res[rc++] = b64[((0x0f & BYTE1)<<2) + (BYTE2>>6)];
        res[rc++] = b64[0x3f & BYTE2];
    }

    if (pad == 2) {
        res[rc++] = b64[bin[byteNo] >> 2];
        res[rc++] = b64[(0x3 & bin[byteNo]) << 4];
        res[rc++] = '=';
        res[rc++] = '=';
    } else if (pad == 1) {
        res[rc++] = b64[bin[byteNo] >> 2 ];
        res[rc++] = b64[((0x3 & bin[byteNo]) << 4) + (bin[byteNo + 1] >> 4)];
        res[rc++] = b64[(0x0f & bin[byteNo+1]) << 2];
        res[rc++] = '=';
    }

    res[rc] = 0;
    return res;
}
