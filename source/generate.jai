
//------------------------------------------------------------------------
// Direction Matrix Generator
//
// The following code is adopted from:
//      https://web.maths.unsw.edu.au/~fkuo/sobol/
//
// The adapted code is under the following license:
//-----------------------------------------------------------------------------
//    Licence pertaining to sobol.cc and the accompanying sets of direction numbers
//
//    -----------------------------------------------------------------------------
//    Copyright (c) 2008, Frances Y. Kuo and Stephen Joe
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions are met:
//
//    * Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
//    * Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
//    * Neither the names of the copyright holders nor the names of the
//    University of New South Wales and the University of Waikato
//    and its contributors may be used to endorse or promote products derived
//    from this software without specific prior written permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
//    EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
//    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//-----------------------------------------------------------------------------

BuildSobolDirectionTable :: (D: int, builder: *String_Builder)
{
    FILE  :: "data/sobol/new-joe-kuo-6.21201";
    L     :: 32; // number of bits

    V : [L + 1]u32;
    m : [L + 1]u32;

    WriteV :: (last_line := false) #expand
    {
        for 1..L
        {
            reversed := V[it];
            print_to_builder(builder, "0x%, ", FormatInt.{value=reversed, base=16, minimum_digits=8});
            if it % 4 == 0 then print_to_builder(builder, "\n");
        }
        if !last_line then print_to_builder(builder, "\n");
    }

    print_to_builder(builder, "SOBOL_MAX_DIMENSION :: %;\n\n", D);
    print_to_builder(builder, "SobolDirectionLUT : [% * %]u32 : .[\n", D, L);

    // First dimension
    for i:1..L
    {
        V[i] = (1 << (32 - i)).(u32);
    }
    WriteV();

    content := read_entire_file(FILE);
    assert(content.count != 0, tprint("Sobol file: '%' could not be read", FILE));

    // Skip first line
    ok:, line:, content = split_from_left(content, #char "\n");
    assert(ok);

    // Remaining dimensions
    for j:1..D-1
    {
        ok, line, content = split_from_left(content, #char "\n");
        assert(ok);

        d:, ok = parse_int(*line, u32);
        assert(ok);

        s:, ok = parse_int(*line, u32);
        assert(ok);

        a:, ok = parse_int(*line, u32);
        assert(ok);

        for i:1..s
        {
            m[i], ok = parse_int(*line, u32);
            assert(ok);
        }

        assert(j + 1 == d);

        if (L <= s)
        {
            for i:1..L
            {
                V[i] = (m[i] << (32 - i)).(u32);
            }
        }
        else
        {
            for i:1..s
            {
                V[i] = (m[i] << (32 - i)).(u32);
            }
            for i:s+1..L
            {
                V[i] = V[i - s] ^ (V[i - s] >> s); 
                for k:1..s-1
                {
                    V[i] ^= (((a >> (s - 1 - k)) & 1) * V[i - k]); 
                }
            }
        }

        WriteV(j == D - 1);
    }

    print_to_builder(builder, "];\n");
}

ReverseBits :: inline (x: u32) -> u32
{
    x = (((x & 0xaaaaaaaa) >> 1) | ((x & 0x55555555) << 1));
    x = (((x & 0xcccccccc) >> 2) | ((x & 0x33333333) << 2));
    x = (((x & 0xf0f0f0f0) >> 4) | ((x & 0x0f0f0f0f) << 4));
    x = (((x & 0xff00ff00) >> 8) | ((x & 0x00ff00ff) << 8));
    return ((x >> 16) | (x << 16));
}

GenerateTables :: ()
{
    set_build_options_dc(.{do_output=false});

    SOBOL_MAX_DIMENSION :: 16;

    builder: String_Builder;

    BuildSobolDirectionTable(SOBOL_MAX_DIMENSION, *builder);
    write_entire_file("sobol_lut.jai", *builder);
}

#run GenerateTables();

#import "File";
#import "Basic";
#import "String";
#import "Compiler";
