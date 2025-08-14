
/*
 Disclaimer: Only works with x64 backend (-x64 flag). For more information see: examples/add_data_segment.jai
 Usage:
 
#run
{
    raddbg_type_view(My_RGBA_Bitmap, "bitmap(data, width, height, rgba)");

    // other type views...
}

#load "raddbg_markup.jai";
*/

raddbg_type_view :: ($type: Type, view: string)
#modify
{
    info := cast (*Type_Info) type;
	return info.type == .STRUCT;
}
{
    info := cast (*Type_Info_Struct) type;
    raddbg_type_view(info.name, view);
}

raddbg_type_view :: (type: string, view: string)
{
    one_time_init();
    data := tprint("type_view: {type: ```%```, expr: ```%```}\0", type, view);
    add_global_data(data.([]u8), .USER_SEGMENT, raddbg_segment);
}

#scope_file

#run raddbg_jai_default_views();

raddbg_jai_default_views :: ()
{
    raddbg_type_view("array_view<?>", "array(data, count)");
    raddbg_type_view("array_resizable<?>", "array(data, count)");
    raddbg_type_view("string", "array(data, count)");

    raddbg_type_view("Vector2", "rows($, x, y)");
    raddbg_type_view("Vector3", "rows($, x, y, z)");
    raddbg_type_view("Vector4", "rows($, x, y, z, w)");
    raddbg_type_view("Quaternion", "rows($, x, y, z, w)");
    raddbg_type_view(Matrix2, "columns($.coef, $[0], $[1]");
    raddbg_type_view(Matrix3, "columns($.coef, $[0], $[1], $[2]");
    raddbg_type_view(Matrix4, "columns($.coef, $[0], $[1], $[2], $[3])");
    raddbg_type_view(Matrix4x3, "columns($.coef, $[0], $[1], $[2], $[3]");

    // Simp.Bitmap
    raddbg_type_view("Bitmap", "bitmap(data, width, height, (format==1)?r:(format==2)?rg:(format==3)?rgba:(format==4)?rgba:(format==0x10)?r16:(format==0x11)?rg16:(format==0x12)?rgba16:(format==0x13)?r32:(format==0x14)?rg32:(format==0x15)?rgba32:r)");

    // unchecked
    raddbg_type_view("relative_array_view<?{T1}, ?{T2}>", "array(cast(T2*)((char*)&data + ((data ^ (0x1ll << (sizeof(data)*8-1))) << (64 - sizeof(data)*8) >> (64 - sizeof(data)*8))), count)");
    raddbg_type_view("relative_string<?>", "array((char*)&data + ((data ^ (0x1ll << (sizeof(data)*8-1))) << (64 - sizeof(data)*8) >> (64 - sizeof(data)*8)), count)");
}

synch_initted  : s32 = 0;
raddbg_segment : *Data_Segment = null;

one_time_init :: ()
{
    one_time_init(*synch_initted, init_synchronization());
}

init_synchronization :: ()
{
    actually : bool;
    raddbg_segment, actually = add_data_segment(".raddbg", .READ | .WRITE);
    add_global_data("\0".([]u8), .USER_SEGMENT, raddbg_segment); // raddbg_is_attached_byte_marker
}

#import "Basic";
#import "Compiler";
