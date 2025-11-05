#load "intersect.jai";
#load "bxdf.jai";
#load "async.jai";

RAYTRACE_BITMAP_WIDTH  :: 1920;
RAYTRACE_BITMAP_HEIGHT :: 1080;

//RAYTRACE_BITMAP_WIDTH  :: 800;
//RAYTRACE_BITMAP_HEIGHT :: 600;

want_screenshot := false;

smoothstep :: inline (a: float, b: float, v: float) -> float
{
    dist := b - a;
    if (dist)
    {
        x := clamp((v - a) / dist, 0.0, 1.0);
        return x * x * (3 - 2 * x);
    }
    return 1;
}

GetPixel :: (x: int, y: int, stride: int, data: *u8, $type: Type, $n: int) -> Vector3
#modify
{
    if (n != 1 && n != 3)
    {
        return false, "Channel must be either 1 or 3";
    }
    if (type != u8 && type != float)
    {
        return false, "Data must be either u8 or float";
    }
    return true;
}
{
    index := y * stride + x * n * size_of(type);
    ptr   := (data + index).(*type);

    r     := ptr[0];
    #if (n == 1)
    {
        g := r;
        b := r;
    }
    else
    {
        g := ptr[1];
        b := ptr[2];
    }

    #if (type == u8)
    {
        rf := saturate(r.(float) / 255.0);
        gf := saturate(g.(float) / 255.0);
        bf := saturate(b.(float) / 255.0);
    }
    else
    {
        rf := r;
        gf := g;
        bf := b;
    }

    return Vector3.{rf, gf, bf};
}

SampleTexture :: (texture: Texture2D, u: float, v: float) -> Vector3
{
    u *= texture.scale.x;
    v *= texture.scale.y;

    // @todo: antialiasing
    // this can be done after we have differentials with du and dv
    // check pbrt for reference

    t := ((u.(int) + v.(int)) & 1).(float);
    c := lerp(texture.constants[0], texture.constants[1], t);

    if (texture.data)
    {
        xp := u * texture.width.(float) - 0.5;
        yp := v * texture.height.(float) - 0.5;

        // Wrap Repeat
        x0 := xp.(int) % texture.width;
        y0 := yp.(int) % texture.height;
        x1 := (x0 + 1) % texture.width;
        y1 := (y0 + 1) % texture.height;

        xf := fract(xp);
        yf := fract(yp);

        samples : [4]Vector3 = ---;

        if #complete texture.format ==
        {
            case .UNKNOWN;
                samples[0] = Vector3.{1, 1, 1};
                samples[1] = Vector3.{1, 1, 1};
                samples[2] = Vector3.{1, 1, 1};
                samples[3] = Vector3.{1, 1, 1};

            case .R8_UNORM;
                samples[0] = GetPixel(x0, y0, texture.stride, texture.data, u8, 1);
                samples[1] = GetPixel(x1, y0, texture.stride, texture.data, u8, 1);
                samples[2] = GetPixel(x0, y1, texture.stride, texture.data, u8, 1);
                samples[3] = GetPixel(x1, y1, texture.stride, texture.data, u8, 1);

            case .R8G8B8_UNORM;
                samples[0] = GetPixel(x0, y0, texture.stride, texture.data, u8, 3);
                samples[1] = GetPixel(x1, y0, texture.stride, texture.data, u8, 3);
                samples[2] = GetPixel(x0, y1, texture.stride, texture.data, u8, 3);
                samples[3] = GetPixel(x1, y1, texture.stride, texture.data, u8, 3);

            case .R32_FLOAT;
                samples[0] = GetPixel(x0, y0, texture.stride, texture.data, float, 1);
                samples[1] = GetPixel(x1, y0, texture.stride, texture.data, float, 1);
                samples[2] = GetPixel(x0, y1, texture.stride, texture.data, float, 1);
                samples[3] = GetPixel(x1, y1, texture.stride, texture.data, float, 1);

            case .R32G32B32_FLOAT;
                samples[0] = GetPixel(x0, y0, texture.stride, texture.data, float, 3);
                samples[1] = GetPixel(x1, y0, texture.stride, texture.data, float, 3);
                samples[2] = GetPixel(x0, y1, texture.stride, texture.data, float, 3);
                samples[3] = GetPixel(x1, y1, texture.stride, texture.data, float, 3);
        }

        avg_x1 := lerp(samples[0], samples[1], xf);
        avg_x2 := lerp(samples[2], samples[3], xf);
        avg    := lerp(avg_x1, avg_x2, yf);

        // @todo: fix this??
        avg.x = clamp(avg.x, 0.0, 1.0);
        avg.y = clamp(avg.y, 0.0, 1.0);
        avg.z = clamp(avg.z, 0.0, 1.0);

        c *= avg;
    }

    return c;
}

SampleAlpha :: (texture: Texture2D, u: float, v: float) -> float
{
    color := SampleTexture(texture, u, v);
    return color.x;
}

sample_uniform_disk_polar :: (u: Vector2) -> Vector2
{
    r := sqrt(u.x);
    theta := 2 * PI * u.y;
    sample: Vector2 = ---;
    sample.x = r * cos(theta);
    sample.y = r * sin(theta);
    return sample;
}

SampleTextureSpectrum :: (texture: Texture2D, u: float, v: float) -> Spectrum
{
    color := SampleTexture(texture, u, v);
    return Spectrum.{color.x, color.y, color.z};
}

material_surface :: (material: Material, hit: HitInfo) -> Surface
{
    surface: Surface = ---;
    surface.color                = SampleTextureSpectrum(material.color, hit.u, hit.v);
    surface.metalness            = SampleAlpha(material.metalness, hit.u, hit.v);
    surface.diffuse_roughness    = SampleAlpha(material.diffuse_roughness, hit.u, hit.v);
    surface.specular_weight      = SampleAlpha(material.specular_weight, hit.u, hit.v);
    surface.specular_color       = SampleTextureSpectrum(material.specular_color, hit.u, hit.v);
    surface.specular_roughness   = SampleAlpha(material.specular_roughness, hit.u, hit.v);
    surface.specular_anisotropic = SampleAlpha(material.specular_anisotropic, hit.u, hit.v);
    surface.specular_ior         = SampleAlpha(material.specular_ior, hit.u, hit.v);
    surface.emission             = SampleTextureSpectrum(material.emission, hit.u, hit.v);
    surface.emission_strength    = SampleAlpha(material.emission_strength, hit.u, hit.v);
    return surface;
}

EncodeSphericalUV :: (n: Vector3) -> Vector2
{
    phi := atan2(n.z, n.x);
    if (phi < 0)
    {
        phi += 2 * PI;
    }
    cos_theta := clamp(n.y, -1.0, 1.0);
    sin_theta := sqrt(1 - cos_theta * cos_theta);
    theta     := acos(cos_theta);
    u         := phi / (2 * PI);
    v         := theta / PI;
    return .{u, v};
}

Ray_Type :: enum
{
    PRIMARY;
    SECONDARY;
}

forward_transform :: (xform: Matrix3, p: Vector3) -> Vector3
{
    r: Vector3 = ---;
    r.x = xform._11 * p.x + xform._12 * p.y + xform._13 * p.z;
    r.y = xform._21 * p.x + xform._22 * p.y + xform._23 * p.z;
    r.z = xform._31 * p.x + xform._32 * p.y + xform._33 * p.z;
    return r;
}

inverse_transform :: (xform: Matrix3, p: Vector3) -> Vector3
{
    r: Vector3 = ---;
    r.x = xform._11 * p.x + xform._21 * p.y + xform._31 * p.z;
    r.y = xform._12 * p.x + xform._22 * p.y + xform._32 * p.z;
    r.z = xform._13 * p.x + xform._23 * p.y + xform._33 * p.z;
    return r;
}

trace_path :: (scene: Scene, primary: Ray, depth: s32, rng: *Path_Random_State, stats: *Path_Statistics) -> Vector3
{
    radiance := Spectrum.{0, 0, 0};
    fr       := Spectrum.{1, 1, 1};
    ray      := primary;
    ray_type := Ray_Type.PRIMARY;

    for 0..depth
    {
        hit         := HitInfo.{ t = -1 };
        num_visited : u32 = 0;

        if (!scene.config.flat_background || ray_type == .PRIMARY)
        {
            hit, num_visited = intersect_scene(scene, ray.origin, ray.dir, ray.tmin, ray.tmax);
        }

        stats.n_bvh_visits += num_visited;

        if hit.t >= 0.0
        {
            //------------------------------------------------------------------------
            // TBN
            N := hit.n;
            T := normalize(hit.dpdu - hit.n * dot(hit.dpdu, hit.n));
            B := cross(N, T);
            handedness := ifx (dot(B, hit.dpdv) < 0.0) then -1.0 else 1.0;
            B *= handedness;

            inv_TBN : Matrix3 = ---;
            inv_TBN.v[0] = T;
            inv_TBN.v[1] = B;
            inv_TBN.v[2] = N;

            //------------------------------------------------------------------------
            // Sample
            material := scene.materials[hit.material_id];
            surface  := material_surface(material, hit);

            next_bounce(rng);
            stats.n_bounces += 1;

            p      := random_sample_1D(rng, .LOBE);
            u      := random_sample_2D(rng, .BxDF);

            V      := forward_transform(inv_TBN, -ray.dir);
            sample := sample_principled_bsdf(V, surface, p, u);

            // @todo: return emission from BSDFSample as well
            emittance := surface.emission_strength * surface.emission;
            radiance += fr * emittance;

            if (sample.pdf < 1.e-6)
            {
                break;
            }

            cosine := saturate(sample.L.z);
            fr *= cosine * sample.fr / sample.pdf;

            //------------------------------------------------------------------------
            // Next ray
            ray.origin = hit.p;
            ray.dir    = inverse_transform(inv_TBN, sample.L);
            ray.tmin   = 1.0e-3;
            ray.tmax   = FLOAT32_MAX;
            ray_type   = .SECONDARY;
        }
        else
        {
            if (!scene.config.flat_background || ray_type == .SECONDARY)
            {
                uv  := EncodeSphericalUV(ray.dir);
                env := SampleTexture(scene.environment, uv.x, uv.y);

                // @todo: is this where exposure goes??
                env *= scene.exposure;

  //              // @todo: fix this??
  //              env.x = clamp(env.x, 0.0, 1.0);
  //              env.y = clamp(env.y, 0.0, 1.0);
  //              env.z = clamp(env.z, 0.0, 1.0);

                radiance += fr * env;
            }
            else
            {
                radiance = scene.flat_background_color;
            }
            break;
        }
    }

    return radiance;
}


BlackmanHarris :: (k: float, N: float) -> float
{
    A0 :: 0.35875;
    A1 :: 0.48829;
    A2 :: 0.14128;
    A3 :: 0.01168;

    x := k / N;
    y := 2 * PI * x;
    w := A0 - A1 * cos(y) + A2 * cos(2 * y) - A3 * cos(3 * y);
    return w;
}

EvaluateFilter :: (type: Filter_Type, k: float, N: float) -> float
{
    if #complete type ==
    {
        case .BOX;
            return 1.0;

        case .BLACKMAN_HARRIS;
            return BlackmanHarris(k, N);
    }
}

EvaluateFilterCDF :: (CDF: []float, a: float, b: float, type: Filter_Type, N: float)
{
    n_samples := CDF.count - 1;
    scale     := 1.0 / n_samples.(float);
    x_range   := b - a;
    dx        := x_range * scale;

    CDF[0] = 0.0;
    for 0..n_samples-1
    {
        x := a + (it + 0.5) * dx;
        y := EvaluateFilter(type, x, N);
        CDF[it + 1] = abs(y) * dx + CDF[it];
    }

    // Normalize
    inv_sum := 0.0;
    if (CDF[n_samples] > 0.0)
    {
        inv_sum = 1.0 / CDF[n_samples];
    }
    for * CDF
    {
        it.* *= inv_sum;
    }
    CDF[n_samples] = 1.0;
}

UpperBound :: (arr: []$T, target: T) -> int
{
    lo := 0;
    hi := arr.count - 1;
    ub := arr.count;
    while (lo <= hi)
    {
        mid := lo + (hi - lo) / 2;

        if (arr[mid] > target)
        {
            ub = mid;
            hi = mid - 1;
        }
        else
        {
            lo = mid + 1;
        }
    }
    return ub;
}

InvertCDF :: (inv_CDF: []float, CDF: []float, a: float, b: float)
{
    assert(inv_CDF.count + 1 == CDF.count);
    assert(CDF.count >= 2 && CDF[0] == 0.0 && CDF[CDF.count - 1] == 1.0);

    x_range   := b - a;
    n_samples := inv_CDF.count;
    scale     := 1.0 / n_samples.(float);

    for 0..n_samples-1
    {
        p     := (it + 0.5) * scale;
        bin   := UpperBound(CDF, p) - 1;
        t     := 0.0;

        if (bin < CDF.count - 1)
        {
            denom := max(CDF[bin + 1] - CDF[bin], 1.0e-6);
            t = (p - CDF[bin]) / denom;
        }

        inv_CDF[it] = a + x_range * (bin + t) * scale;
    }
}

SampleCameraFilter :: inline (camera: Camera, u: Vector2) -> Vector2
{
    x := read_lookup_table_1D(camera.filter_lut, FILTER_SIZE, u.x);
    y := read_lookup_table_1D(camera.filter_lut, FILTER_SIZE, u.y);
    return .{x, y};
}

// @todo: remove this
HashTemp :: (x: u32, seed: u32) -> u32
{
    // Mix seed with x via rotate left
    x ^= (seed << 23) | (seed >> 9);

    // Finalizer from murmurhash3
    x ^= x >> 16;
    x *= 0x85ebca6b;
    x ^= x >> 13;
    x *= 0xc2b2ae35;
    x ^= x >> 16;
    return x;
}

IsPower2 :: (v: u32) -> bool
{
    return v && !(v & (v - 1));
}

NextPowerOf2 :: (n: u32) -> u32
{
    if (IsPower2(n))
        return n;
    count : u32 = 0;
    while (n != 0)
    {
        n >>= 1;
        count += 1;
    }
    return (1 << count).(u32);
}

RenderPixel :: (scene: Scene, x: u32, y: u32, frame: u32, stats: *Path_Statistics) -> Vector3
{
    origin     := Vector2.{x.(float), y.(float)};
    width      := scene.config.width;
    height     := scene.config.height;

    scale      := Vector2.{ 2.0 / (width - 1).(float), 2.0 / (height - 1).(float) };
    shift      := Vector2.{ -1.0, -1.0 };

    radiance   := Vector3.{0, 0, 0};

    spp        := NextPowerOf2(scene.config.multisamples);

    seed       := HashTemp(frame, 7);

    for 0..spp-1
    {
        rng        := path_random_state(x, y, it.(u32), spp, seed);

        filter_uv  := random_sample_2D(rng, .FILTER);
        subpixel   := SampleCameraFilter(scene.camera, filter_uv);
        sample     := origin + subpixel;

        // To NDC
        pixel      := sample * scale + shift;

        lens_uv    := random_sample_2D(rng, .LENS);
        ray        := generate_ray(pixel, scene.camera, lens_uv);
        radiance   += trace_path(scene, ray, scene.config.max_depth, *rng, stats);
    }

    radiance /= spp.(float);
    return radiance;
}

RAY_TRACE_TILE_SIZE : s32 : 16;

Render_Shared :: struct
{
    tile_id: int;
}

ApplyToneMapping :: (func: Tone_Map_Type, v: Vector3) -> Vector3
{
    if #complete func ==
    {
        case .LINEAR;
            return Vector3.{saturate(v.x), saturate(v.y), saturate(v.z)};
        case .REINHARD;
            return v / (Vector3.{1, 1, 1} + v);
    }
}

SpiralCoordinates :: (n: int) -> (x: int, y: int)
{
    if (n == 0)
    {
        return 0, 0;
    }

    k := ceil((sqrt(n.(float) + 1) - 1) / 2).(int);
    l := 2 * k + 1;
    t := l - 1;
    m := l * l;

    if (n >= m - t)
    {
        x := k - (m - n);
        y := -k;
        return x, y;
    }

    m -= t;
    if (n >= m - t)
    {
        x := -k;
        y := -k + (m - n);
        return x, y;
    }

    m -= t;
    if (n >= m - t)
    {
        x := -k + (m - n);
        y := k;
        return x, y;
    }

    x := k;
    y := k - (m - n - t);

    return x, y;
}

// @todo: cleanup this global variable
render_shared: Render_Shared;

render :: (scene: *Scene, weight: float, frame: u32)
{
    width  := scene.config.width;
    height := scene.config.height;

    // @todo: cleanup RAY_TRACE_TILE_SIZE
  //  assert(width % RAY_TRACE_TILE_SIZE == 0);
  //  assert(height % RAY_TRACE_TILE_SIZE == 0);

    num_tile_w := width / RAY_TRACE_TILE_SIZE;
    num_tile_h := height / RAY_TRACE_TILE_SIZE;

    if context.lane.index == 0
    {
        atomic_write(*render_shared.tile_id, 0);
    }

    lane_sync();

    max_tile_d := max(num_tile_w, num_tile_h);
    num_tiles  := max_tile_d * max_tile_d;
    offset_x   := (num_tile_w - 1) / 2;
    offset_y   := (num_tile_h - 1) / 2;

    while !should_quit
    {
        captured_tile_id := atomic_add(*render_shared.tile_id, 1);

        if captured_tile_id >= num_tiles then break;

        tile_x, tile_y := SpiralCoordinates(captured_tile_id);
        tile_x += offset_x;
        tile_y += offset_y;

        if (tile_x < 0 || tile_x >= num_tile_w || tile_y < 0 || tile_y >= num_tile_h)
            continue;

        y0 := tile_y * RAY_TRACE_TILE_SIZE;
        y1 := y0 + RAY_TRACE_TILE_SIZE - 1;

        x0 := tile_x * RAY_TRACE_TILE_SIZE;
        x1 := x0 + RAY_TRACE_TILE_SIZE - 1;

        if x1 >= width  then x1 = width - 1;
        if y1 >= height then y1 = height - 1;

        //offset := captured_tile_id * RAY_TRACE_TILE_SIZE * RAY_TRACE_TILE_SIZE;

        for y:y0..y1
        {
            for x:x0..x1
            {
                stats := *scene.statistics[y * width + x];
                color := RenderPixel(scene, x.(u32), y.(u32), frame, stats);

                //color := trace_pixel(scene, x.(s32), y.(s32), num_samples);

                index := y * width + x;
                //index := offset;
                //offset += 1;

                //color *= inv_samples;
                prev_color := scene.rgbx[index].xyz;
                
                render := lerp(prev_color, color, weight);

                scene.rgbx[index].xyz = render;

                // @todo: proper Tone Mapping + Gamma correction
                // https://64.github.io/tonemapping/
                // @todo: use exposure!!
                render = ApplyToneMapping(scene.tonemap, render);

                Clamp(*render.x, 0.0, 1.0);
                Clamp(*render.y, 0.0, 1.0);
                Clamp(*render.z, 0.0, 1.0);

                write_color(scene.bitmap, x, y, render);
            }
        }
    }

    lane_sync();
}

write_color :: (bitmap: Bitmap, x: int, y: int, linear: Vector3, $srgb: bool = true)
{
    index := (bitmap.height - y - 1) * bitmap.stride + x * 4;

    #if srgb
    {
        color := linear_to_srgb(linear);
    }
    else
    {
        color := linear;
    }

    r := (color.x * 255).(u8);
    g := (color.y * 255).(u8);
    b := (color.z * 255).(u8);

    bitmap.data[index + 0] = r;
    bitmap.data[index + 1] = g;
    bitmap.data[index + 2] = b;
    bitmap.data[index + 3] = 0xFF;
}

SceneType :: enum
{
    basic_light;
    cornell_box;
    cornell_dragon;
    cornell_monkey;
    white_furnace_test;
    shaderball_test;
    material_test;
    envmap_test;
}

white_furnace_test_enabled   := false;
white_furnace_test_error     := 0.0;
white_furnace_test_bias      := 0.0;
white_furnace_test_max_error := 0.0;

wavefront_raytrace_entry :: (thread: *Thread) -> s64
{
    scene := thread.data.(*Scene);

    width  := scene.config.width;
    height := scene.config.height;

    screenshot_index := 0;

    if context.lane.index == 0
    {
        screenshot_index = get_first_screenshot_index("captures");
    }

    while (!should_quit)
    {
        weight := 1.0 / (frame_index.(float) + 1);

        t0 := current_time_monotonic();

        print("scene.type = %\n", scene.camera.type);

        render(scene, weight, frame_index.(u32));

        t1 := current_time_monotonic();

        if context.lane.index == 0
        {
            last_frame_render_time_ms = to_milliseconds(t1 - t0);
            frame_index += 1;

            if want_screenshot || (frame_index % 12) == 0
            {
                save_screenshot(scene.bitmap, *screenshot_index);
                want_screenshot = false;
            }

            if white_furnace_test_enabled
            {
                error     := 0.0;
                max_error := 0.0;
                bias      := 0.0;
                for scene.rgbx
                {
                    e := it.x * it.x + it.y * it.y + it.z * it.z;
                    error += abs(e - 3);
                    bias  += (e - 3);
                    max_error = max(max_error, abs(e - 3));
                }
                white_furnace_test_error     = error / (scene.rgbx.count);
                white_furnace_test_bias      = bias / (scene.rgbx.count);
                white_furnace_test_max_error = max_error;
                print("White Furnace Test dE = %\%, bias = %\%, max error = %\n", white_furnace_test_error * 100, white_furnace_test_bias * 100, white_furnace_test_max_error);
            }

            // heatmap

            max_bounces := 1; // prevent division by zero
            max_bvh_visits := 1;

            for scene.statistics
            {
                max_bounces = max(max_bounces, it.n_bounces);
                max_bvh_visits = max(max_bvh_visits, it.n_bvh_visits);
            }

            for y:0..height-1
            {
                for x:0..width-1
                {
                    stats := *scene.statistics[y * width + x];
                    WriteHeatMap(scene.bounces_heatmap, x, y, stats.n_bounces.(float) / max_bounces.(float));
                    WriteHeatMap(scene.bvh_visits_heatmap, x, y, stats.n_bvh_visits.(float) / max_bvh_visits.(float));
                }
            }
        }

        lane_sync();
    }

    return 0;
}

WriteHeatMap :: (bitmap: Bitmap, x: int, y: int, alpha: float)
{
    // Visible Spectrum: https://learn.microsoft.com/en-us/bingmaps/v8-web-control/map-control-concepts/heat-map-module-examples/heat-map-color-gradients

    HEAT_COLORS :: Vector3.[.{1, 0, 1}, .{0, 0, 1}, .{0, 1, 0}, .{1, 1, 0}, .{1, 0, 0}];

    segment_count := HEAT_COLORS.count - 1;
    scaled_alpha  := clamp(alpha, 0.0, 1.0) * segment_count;
    index         := scaled_alpha.(int);
    local_t       := scaled_alpha - index;

    // @todo: fix indexing
  //  color := lerp(HEAT_COLORS[index], HEAT_COLORS[index + 1], local_t);

  //  write_color(bitmap, x, y, color, false);
}

make_matrix4x3 :: (m: Matrix4) -> Matrix4x3
{
    r: Matrix4x3 = ---;
    r._11 = m._11; r._12 = m._12; r._13 = m._13; r._14 = m._14;
    r._21 = m._21; r._22 = m._22; r._23 = m._23; r._24 = m._24;
    r._31 = m._31; r._32 = m._32; r._33 = m._33; r._34 = m._34;
    return r;
}

load_bunny :: () -> Primitive_Mesh, Matrix4
{
    theta := 20.0 / 360.0 * 2 * PI;

    rot: Quaternion;

    set_from_axis_and_angle(*rot, 0, 1, 0, theta);

    scale := 300.0;

    bunny := load_obj_model("data/bunny/bunny.obj");
    xform := make_translation_matrix4(.{270, 90, 270}) * rotation_matrix(Matrix4, rot) * make_scale_matrix4(.{scale, scale, scale});

    return bunny, xform;
}

load_monkey :: () -> Primitive_Mesh, Matrix4
{
    theta := 30.0 / 360.0 * 2 * PI;

    rot: Quaternion;

    set_from_axis_and_angle(*rot, 0, 1, 0, theta);

    scale := 200.0;

    monkey := load_obj_model("data/spot/spot_triangulated.obj");
    xform  := make_translation_matrix4(.{270, 140, 270}) * rotation_matrix(Matrix4, rot) * make_scale_matrix4(.{scale, scale, scale});

    return monkey, xform;
}

load_dragon :: () -> Primitive_Mesh, Matrix4
{
    theta := 90.0 / 360.0 * 2 * PI;

    rot: Quaternion;

    set_from_axis_and_angle(*rot, 0, 1, 0, theta);

    scale := 500.0;

    dragon := load_obj_model("data/dragon/dragon.obj");
    xform  := make_translation_matrix4(.{270, 140, 270}) * rotation_matrix(Matrix4, rot) * make_scale_matrix4(.{scale, scale, scale});

    return dragon, xform;
}

load_backdrop :: () -> Primitive_Mesh, Matrix4
{
    scale := 2.0;
    position := Vector3.{0, 0, -10.1};
    backdrop := load_obj_model("data/backdrop/Backdrop.obj");
    xform    := make_translation_matrix4(position) * make_scale_matrix4(.{scale, scale, scale});
    return backdrop, xform;
}

load_shaderball :: () -> Primitive_Mesh, Primitive_Mesh, Matrix4
{
    scale := 0.5;
    position := Vector3.{0, 0, 0};

  //  internals := load_obj_model("data/shaderball/shader_ball_internals.obj");
  //  externals := load_obj_model("data/shaderball/shader_ball_externals.obj");

    internals := load_obj_model("data/shaderball/shader_ball_bmps_inner.obj");
    externals := load_obj_model("data/shaderball/shader_ball_bmps_outer.obj");

    theta := -30.0 / 360.0 * 2 * PI;

    orientation: Quaternion;
    set_from_axis_and_angle(*orientation, 0, 1, 0, theta);

    xform    := make_translation_matrix4(position) * rotation_matrix(Matrix4, orientation) * make_scale_matrix4(.{scale, scale, scale});
    return internals, externals, xform;
}

quaternion_between_vectors :: (from: Vector3, to: Vector3) -> Quaternion
{
    q: Quaternion;
    w := 1.0 + dot(from, to);
    if (w)
    {
        v  := cross(from, to);
        q.x = v.x;
        q.y = v.y;
        q.z = v.z;
        q.w = w;
    }
    else
    {
        xyz := ifx abs(from.x) > abs(from.z)
                Vector3.{-from.y, from.x, 0.0}
               else
                Vector3.{0.0, -from.z, from.y};
        q = .{xyz.x, xyz.y, xyz.z, w};
    }
    return normalize(q);
}

lookat :: (from: Vector3, to: Vector3, world_forward: Vector3) -> Quaternion
{
    dir := to - from;
    return quaternion_between_vectors(world_forward, dir);
}

turns_to_radians :: (turns: float) -> float
{
    return turns * 2.0 * PI;
}

load_scene :: (using scene: *Scene, type: SceneType)
{
    envtex := load_texture_from_file("data/envmap/citrus_orchard_road_puresky_2k.hdr");

    if #complete type ==
    {
        case .basic_light;
            camera.fov           = 40.0 / 360.0;
            camera.position      = .{0, 0, -30};

            theta1 := -18.0 / 360.0 * 2 * PI;
            theta2 := 15.0 / 360.0 * 2 * PI;

            rot1, rot2: Quaternion;

            set_from_axis_and_angle(*rot1, 0, 1, 0, theta1);
            set_from_axis_and_angle(*rot2, 0, 1, 0, theta2);

            xform1 := rotation_matrix(Matrix4, rot1);
            xform2 := rotation_matrix(Matrix4, rot2);

            red   := create_lambertian_material(scene, create_constant_texture(.{0.65, 0.05, 0.05}));

            //add_translated_box(scene, xform1, .{-10, -5, -10}, .{5, 5, 25}, red);

            add_sphere(scene, Vector3.{15, 15, 75}, 5, red);

        case .cornell_box;
            camera.fov           = 40.0 / 360.0;
            camera.position      = .{278, 278, -800};

            //camera.lens_focal_length = 1200;
            //camera.lens_radius = 10.0;

            environment = create_constant_texture(.{0, 0, 0});

            red   := create_lambertian_material(scene, create_constant_texture(.{0.65, 0.05, 0.05}));
            white := create_lambertian_material(scene, create_constant_texture(.{0.73, 0.73, 0.73}));
            metal := create_metal_material(scene, roughness=0.3, specular_tint=.{1.000, 0.735, 0.353}, base_color=.{0.993, 1.000, 1.000});
            green := create_lambertian_material(scene, create_constant_texture(.{0.12, 0.45, 0.15}));
            light := create_emission_material(scene, create_constant_texture(.{15, 15, 15}));

            add_box(scene, Matrix4_Identity, .{213, 554, 227}, .{343, 554.01, 332}, light); // top
            add_box(scene, Matrix4_Identity, .{0, 0, 0}, .{0.01, 555, 555}, green); // left
            add_box(scene, Matrix4_Identity, .{555, 0, 0}, .{555.01, 555, 555}, red); // right
            add_box(scene, Matrix4_Identity, .{0, 0, 0}, .{555, 0.01, 555}, white); // bottom
            add_box(scene, Matrix4_Identity, .{0, 0, 555}, .{555, 555, 555.01}, white); // back
            add_box(scene, Matrix4_Identity, .{0, 555, 0}, .{555, 555.01, 555}, white); // top

            theta1 := 18.0 / 360.0 * 2 * PI;
            theta2 := -15.0 / 360.0 * 2 * PI;

            rot1, rot2: Quaternion;

            set_from_axis_and_angle(*rot1, 0, 1, 0, theta1);
            set_from_axis_and_angle(*rot2, 0, 1, 0, theta2);

            xform1 := rotation_matrix(Matrix4, rot1);
            xform2 := rotation_matrix(Matrix4, rot2);

            add_translated_box(scene, xform1, .{260, 0,  65}, .{425, 165, 225}, white);
            add_translated_box(scene, xform2, .{130, 0, 295}, .{290, 330, 455}, metal);

        case .cornell_dragon;
            camera.fov           = 40.0 / 360.0;
            camera.position      = .{278, 278, -800};

            environment = create_constant_texture(.{0, 0, 0});
            //environment          = .{0.3, 0.2, 0.7};

            red   := create_lambertian_material(scene, create_constant_texture(.{0.65, 0.05, 0.05}));
            white := create_lambertian_material(scene, create_constant_texture(.{0.73, 0.73, 0.73}));
            green := create_lambertian_material(scene, create_constant_texture(.{0.12, 0.45, 0.15}));
            light := create_emission_material(scene, create_constant_texture(.{15, 15, 15}));

            add_box(scene, Matrix4_Identity, .{213, 554, 227}, .{343, 554.01, 332}, light);
            add_box(scene, Matrix4_Identity, .{0, 0, 0}, .{0.01, 555, 555}, green); // left
            add_box(scene, Matrix4_Identity, .{555, 0, 0}, .{555.01, 555, 555}, red); // right
            add_box(scene, Matrix4_Identity, .{0, 0, 0}, .{555, 0.01, 555}, white); // bottom
            add_box(scene, Matrix4_Identity, .{0, 0, 555}, .{555, 555, 555.01}, white); // back
            add_box(scene, Matrix4_Identity, .{0, 555, 0}, .{555, 555.01, 555}, white); // top

            dragon_material := create_lambertian_material(scene, create_constant_texture(.{1, 1, 1}));
            dragon, xform   := load_dragon();

            add_mesh(scene, xform, dragon, dragon_material);

        case .cornell_monkey;
            camera.fov           = 40.0 / 360.0;
            camera.position      = .{278, 278, -800};

            environment = create_constant_texture(.{0, 0, 0});
            //environment          = .{0.3, 0.2, 0.7};

            red   := create_lambertian_material(scene, create_constant_texture(.{0.65, 0.05, 0.05}));
            white := create_lambertian_material(scene, create_constant_texture(.{0.73, 0.73, 0.73}));
            green := create_lambertian_material(scene, create_constant_texture(.{0.12, 0.45, 0.15}));
            light := create_emission_material(scene, create_constant_texture(.{15, 15, 15}));

            add_box(scene, Matrix4_Identity, .{213, 554, 227}, .{343, 554.01, 332}, light); // top
            add_box(scene, Matrix4_Identity, .{0, 27, 227}, .{0.1, 127, 327}, light); // left

            add_box(scene, Matrix4_Identity, .{0, 0, 0}, .{0.01, 555, 555}, green); // left
            add_box(scene, Matrix4_Identity, .{555, 0, 0}, .{555.01, 555, 555}, red); // right
            add_box(scene, Matrix4_Identity, .{0, 0, 0}, .{555, 0.01, 555}, white); // bottom
            add_box(scene, Matrix4_Identity, .{0, 0, 555}, .{555, 555, 555.01}, white); // back
            add_box(scene, Matrix4_Identity, .{0, 555, 0}, .{555, 555.01, 555}, white); // top

            monkey, xform := load_monkey();

            add_mesh(scene, xform, monkey, white);

        case .white_furnace_test;
            white_furnace_test_enabled = true;

            camera.fov         = 45.0 / 360.0;
            camera.position    = .{0, 0, -5};
            camera.orientation = .{};
            environment        = create_constant_texture(.{1, 1, 1});
            exposure           = 1.0;

            center  := Vector3.{0.0, 0.0, 0.0};
            radius  := 1.0;

            id, material        := create_material(scene);
            material.color       = create_constant_texture(.{1, 1, 1});
            material.metalness   = create_constant_texture(0.0);
            material.diffuse_roughness    = create_constant_texture(0.0);
            material.specular_weight      = create_constant_texture(1.0);
            material.specular_color       = create_constant_texture(.{1, 1, 1});
            material.specular_roughness   = create_constant_texture(0.8);
            material.specular_anisotropic = create_constant_texture(0.0);
            material.specular_ior         = create_constant_texture(1.5);

            add_sphere(scene, center, radius, id);

        case .shaderball_test;
            camera.fov           = 40.0 / 360.0;
            camera.position      = .{0, 10, -10};
            set_from_axis_and_angle(*camera.orientation, Vector3.{1, 0, 0}, turns_to_radians(0.1));

            light := create_emission_material(scene, create_constant_texture(.{40, 40, 40}));

            environment = envtex;
            exposure    = 1;

            id, material        := create_material(scene);
            //material.color       = create_constant_texture(.{0.827, 0.686, 0.216});
            material.color       = create_constant_texture(.{0.699, 0.704, 0.671}); // Cobalt
            //material.color       = create_constant_texture(.{1, 1, 1});
            //material.color       = create_constant_texture(.{1.000, 0.735, 0.353}); // Gold
            material.metalness   = create_constant_texture(0.0);
            material.diffuse_roughness    = create_constant_texture(1.0);
            material.specular_weight      = create_constant_texture(0.7);
            //material.specular_color       = create_constant_texture(.{1, 1, 1});
            //material.specular_color       = create_constant_texture(.{0.993, 1.000, 1.000}); // Gold
            material.specular_color       = create_constant_texture(.{0.727, 0.772, 0.823}); // Cobalt
            material.specular_roughness   = create_constant_texture(0.25);
            material.specular_anisotropic = create_constant_texture(0.0);
            material.specular_ior         = create_constant_texture(2.5);

            white      := create_lambertian_material(scene, create_constant_texture(.{1, 1, 1}));
            red        := create_lambertian_material(scene, create_constant_texture(.{0.65, 0.05, 0.05}));
            black      := create_lambertian_material(scene, create_constant_texture(.{0.1, 0.1, 0.1}));
            checker    := create_lambertian_material(scene, create_checkerboard_texture(Vector3.{0.9, 0.9, 0.9}, .{0.1, 0.1, 0.1}, .{40, 40}));

            earth      := load_texture_from_file("data/misc/earth.png", 3);
            textured   := create_lambertian_material(scene, earth);

            backdrop, backdrop_xform     := load_backdrop();
            internals, externals, shaderball_xform := load_shaderball();

            add_box(scene, Matrix4_Identity, .{ -5, 10, -15 }, .{ -1, 10.01, -11 }, light);
            add_box(scene, Matrix4_Identity, .{  1, 10, -15 }, .{  5, 10.01, -11 }, light);

            //add_sphere(scene, Vector3.{0, 2, 0}, 2, textured);

            add_mesh(scene, backdrop_xform, backdrop, checker);
            //add_sphere(scene, Vector3.{0, 2, 0}, 2, id);
            add_mesh(scene, shaderball_xform, internals, black);
            add_mesh(scene, shaderball_xform, externals, id);

        case .material_test;
            camera.fov         = 45.0 / 360.0;
            camera.position    = .{0, 0, -5};
            camera.orientation = .{};

            camera.type = .ORTHOGRAPHIC;

            //environment        = load_texture_from_file("data/envmap/golden_gate_hills_2k.hdr");

            environment        = create_constant_texture(.{1, 1, 1});
            exposure = 1.0;

            //config.flat_background = true;

            NUM_TEST_SPHERES :: 10;

            radius  := 0.3;
            spacing := 2 * radius + 0.1;
            start_x := -3.1;
            start_y :=  1.5;

            // Backdrop
            {
                checker := create_lambertian_material(scene, create_checkerboard_texture(Vector3.{0.9, 0.9, 0.9}, .{0.1, 0.1, 0.1}, .{40, 40}));
                add_box(scene, Matrix4_Identity, .{-6, -6, 0.5}, .{6, 6, 0.6}, checker); // back
            }

            // Diffuse (Roughness)
            {
                color   := Vector3.{0.02, 0.53, 0.42};
                center  := Vector3.{start_x, start_y, 0.0};
                start_y -= spacing;

                for 0..NUM_TEST_SPHERES-1
                {
                    roughness := it.(float) / (NUM_TEST_SPHERES - 1).(float);
                    material  := create_lambertian_material(scene, create_constant_texture(color), roughness);
                    add_sphere(scene, center, radius, material);
                    center.x += spacing;
                }
            }

            // Metal (Roughness)
            {
                center  := Vector3.{start_x, start_y, 0.0};
                start_y -= spacing;

                for 0..NUM_TEST_SPHERES-1
                {
                    roughness := it.(float) / (NUM_TEST_SPHERES - 1).(float);

                    id, material                 := create_material(scene);
                    material.color                = create_constant_texture(.{1.000, 0.735, 0.353}); // Gold
                    material.metalness            = create_constant_texture(1.0);
                    material.specular_weight      = create_constant_texture(1.0);
                    material.specular_color       = create_constant_texture(.{0.993, 1.000, 1.000}); // Gold
                    material.specular_roughness   = create_constant_texture(roughness);
                    material.specular_anisotropic = create_constant_texture(0.0);

                    add_sphere(scene, center, radius, id);
                    center.x += spacing;
                }
            }

            // Metal (Anisotropic)
            {
                roughness := 0.5;
                center    := Vector3.{start_x, start_y, 0.0};
                start_y   -= spacing;

                for 0..NUM_TEST_SPHERES-1
                {
                    anisotropic := it.(float) / (NUM_TEST_SPHERES - 1).(float);

                    id, material                 := create_material(scene);
                    material.color                = create_constant_texture(.{0.617, 0.576, 0.540}); // Titanium
                    material.metalness            = create_constant_texture(1.0);
                    material.specular_weight      = create_constant_texture(1.0);
                    material.specular_color       = create_constant_texture(.{0.695, 0.726, 0.770}); // Titanium
                    material.specular_roughness   = create_constant_texture(roughness);
                    material.specular_anisotropic = create_constant_texture(anisotropic);

                    add_sphere(scene, center, radius, id);
                    center.x += spacing;
                }
            }

            // Dielectric (Roughness)
            {
                center  := Vector3.{start_x, start_y, 0.0};
                start_y -= spacing;

                for 0..NUM_TEST_SPHERES-1
                {
                    roughness := it.(float) / (NUM_TEST_SPHERES - 1).(float);

                    id, material                 := create_material(scene);
                    material.color                = create_constant_texture(.{0.89, 0.77, 0.13});
                    material.metalness            = create_constant_texture(0.0);
                    material.specular_weight      = create_constant_texture(1.0);
                    material.specular_color       = create_constant_texture(.{1.000, 1.000, 1.000});
                    material.specular_roughness   = create_constant_texture(roughness);
                    material.specular_anisotropic = create_constant_texture(0.0);
                    material.specular_ior         = create_constant_texture(1.5);

                    add_sphere(scene, center, radius, id);
                    center.x += spacing;
                }
            }

            // Dielectric (IOR)
            {
                center    := Vector3.{start_x, start_y, 0.0};
                start_y   -= spacing;
                roughness := 0.25;

                ior_1 := 1.0;
                ior_2 := 2.5;

                color   := Vector3.{0.02, 0.53, 0.42};

                for 0..NUM_TEST_SPHERES-1
                {
                    t := it.(float) / (NUM_TEST_SPHERES - 1).(float);
                    ior := lerp(ior_1, ior_2, t);

                    id, material                 := create_material(scene);
                    material.color                = create_constant_texture(color);
                    material.metalness            = create_constant_texture(0.0);
                    material.specular_weight      = create_constant_texture(1.0);
                    material.specular_color       = create_constant_texture(.{1.000, 1.000, 1.000});
                    material.specular_roughness   = create_constant_texture(roughness);
                    material.specular_anisotropic = create_constant_texture(0.0);
                    material.specular_ior         = create_constant_texture(ior);

                    add_sphere(scene, center, radius, id);
                    center.x += spacing;
                }
            }

        case .envmap_test;
            camera.fov         = 45.0 / 360.0;
            camera.position    = .{0, 0, -5};
            camera.orientation = .{};
            environment        = envtex;
    }
}

add_primitive :: (scene: *Scene, type: Primitive_Type) -> *Primitive
{
    primitive := array_add(*scene.primitives);
    primitive.type = type;
    return primitive;
}

add_sphere :: (scene: *Scene, xform: Matrix4, radius: float, material_id: MaterialID)
{
    if radius <= 0.0 then
        radius = 1;

    center := transform_point(xform, Vector3.{0, 0, 0});
    _, inv := inverse(xform);

    primitive := add_primitive(scene, .SPHERE);
    primitive.shape.sphere.radius = radius;
    primitive.xform.forward = make_matrix4x3(xform);
    primitive.xform.inverse = make_matrix4x3(inv);
    primitive.material_id = material_id;
}

add_sphere :: (scene: *Scene, center: Vector3, radius: float, material_id: MaterialID)
{
    xform := make_translation_matrix4(center);
    add_sphere(scene, xform, radius, material_id);
}

add_disk :: (scene: *Scene, p: Vector3, radius: float, material_id: MaterialID)
{
    if radius <= 0.0 then
        radius = 1;

    primitive := add_primitive(scene, .DISK);
    primitive.shape.disk.radius = radius;
    primitive.xform.forward = make_matrix4x3(make_translation_matrix4(p));
    primitive.xform.inverse = make_matrix4x3(make_translation_matrix4(-p));
    primitive.material_id = material_id;
}

add_box :: (scene: *Scene, xform: Matrix4, min: Vector3, max: Vector3, material_id: MaterialID)
{
    _, inv := inverse(xform);
    primitive := add_primitive(scene, .BOX);
    primitive.shape.box.vmin = min;
    primitive.shape.box.vmax = max;
    primitive.xform.forward = make_matrix4x3(xform);
    primitive.xform.inverse = make_matrix4x3(inv);
    primitive.material_id = material_id;
}

add_box :: (scene: *Scene, xform: Matrix4, material_id: MaterialID)
{
    add_box(scene, xform, Vector3.{-0.5, -0.5, -0.5}, Vector3.{0.5, 0.5, 0.5}, material_id);
}

add_translated_box :: (scene: *Scene, xform: Matrix4, p: Vector3, q: Vector3, material_id: MaterialID)
{
    pmin := min(p, q);
    pmax := max(p, q);

    dx := Vector3.{pmax.x - pmin.x, 0, 0};
    dy := Vector3.{0, pmax.y - pmin.y, 0};
    dz := Vector3.{0, 0, pmax.z - pmin.z};

    h := 0.5 * (pmin + pmax);
    d := 0.5 * (pmax - pmin);

    add_box(scene, make_translation_matrix4(h) * xform, -d, d, material_id);
}

add_mesh :: (scene: *Scene, xform: Matrix4, mesh: Primitive_Mesh, material_id: MaterialID)
{
    primitive := add_primitive(scene, .MESH);

    primitive.shape.mesh = mesh;

    _, inv := inverse(xform);

    primitive.xform.forward = make_matrix4x3(xform);
    primitive.xform.inverse = make_matrix4x3(inv);
    primitive.material_id = material_id;
}

create_material :: (scene: *Scene) -> MaterialID, *Material
{
    id       := scene.materials.count.(MaterialID);
    material := array_add(*scene.materials);
    return id, material;
}

create_lambertian_material :: (scene: *Scene, color: Texture2D, roughness := 0.0) -> MaterialID
{
    id, material := create_material(scene);
    material.color = color;
    material.diffuse_roughness = create_constant_texture(roughness);
    return id;
}

create_metal_material :: (scene: *Scene, roughness := 0.0, specular_tint := Vector3.{1, 1, 1}, base_color := Vector3.{1, 1, 1}) -> MaterialID
{
    id, material := create_material(scene);
    material.metalness = create_constant_texture(1.0);
    material.specular_roughness = create_constant_texture(roughness);
    material.color = create_constant_texture(base_color);
    material.specular_color = create_constant_texture(specular_tint);
    return id;
}

create_emission_material :: (scene: *Scene, color: Texture2D, strength := 1.0) -> MaterialID
{
    id, material := create_material(scene);
    material.emission = color;
    material.emission_strength = create_constant_texture(strength);
    return id;
}

create_constant_texture :: (color: Vector3) -> Texture2D
{
    texture: Texture2D;
    texture.scale     = Vector2.{1, 1};
    texture.constants = .[color, color];
    return texture;
}

create_constant_texture :: (alpha: float) -> Texture2D
{
    return create_constant_texture(Vector3.{alpha, alpha, alpha});
}

create_checkerboard_texture :: (color_0: Vector3, color_1: Vector3, scale := Vector2.{1, 1}) -> Texture2D
{
    texture: Texture2D;
    texture.scale = scale;
    texture.constants = .[color_0, color_1];
    return texture;
}

create_checkerboard_texture :: (alpha_0: float, alpha_1: float, scale := Vector2.{1, 1}) -> Texture2D
{
    return create_checkerboard_texture(Vector3.{alpha_0, alpha_0, alpha_0}, Vector3.{alpha_1, alpha_1, alpha_1}, scale);
}

load_texture_from_file :: (path: string, desired_num_channels := 0) -> Texture2D
{
    w, h, channels: s32;

    if (ends_with(path, ".hdr"))
    {
        data := stbi_loadf(temp_c_string(path), *w, *h, *channels, 0);
        assert(channels == 1 || channels == 3, "Unsupported image format");

        if (!data)
        {
            print("Failed to load texture: %. Reason: %\n", path, stbi_failure_reason());
            return .{};
        }

        texture := create_constant_texture(.{1, 1, 1});
        texture.format = ifx channels == 1 then .R32_FLOAT else .R32G32B32_FLOAT;
        texture.width  = w.(u32);
        texture.height = h.(u32);
        texture.stride = w.(u32) * channels.(u32) * size_of(float);
        texture.data   = data.(*u8);
        return texture;
    }
    else
    {
        data    := stbi_load(temp_c_string(path), *w, *h, *channels, 0);
        assert(channels == 1 || channels == 3, "Unsupported image format");

        if (!data)
        {
            print("Failed to load texture: %. Reason: %\n", path, stbi_failure_reason());
            return .{};
        }

        texture := create_constant_texture(.{1, 1, 1});
        texture.format = ifx channels == 1 then .R8_UNORM else .R8G8B8_UNORM;
        texture.width  = w.(u32);
        texture.height = h.(u32);
        texture.stride = w.(u32) * channels.(u32) * size_of(u8);
        texture.data   = data;
        return texture;
    }
}

init_scene :: (scene: *Scene, width: s32, height: s32, multisamples: u32 = 16, max_depth: s32 = 5, filter := Filter.{})
{
    create_lambertian_material(scene, create_constant_texture(.{0, 0, 0}));
    Simp.bitmap_alloc(*scene.bitmap, width, height, .RGBA8);
    Simp.bitmap_alloc(*scene.bounces_heatmap, width, height, .RGBA8);
    Simp.bitmap_alloc(*scene.bvh_visits_heatmap, width, height, .RGBA8);
    //scene.bitmap.flags |= .IS_SRGB; // @todo: fix this flag!!!

    scene.config.width        = width.(u32);
    scene.config.height       = height.(u32);
    scene.config.multisamples = multisamples;
    scene.config.max_depth    = max_depth;

    CACHE_LINE_SIZE :: 64; // mac?

    scene.rgbx, scene.rgbx_mem = NewArray(scene.config.width * scene.config.height, Vector4, alignment=CACHE_LINE_SIZE);
    scene.statistics, scene.statistics_mem = NewArray(scene.config.width * scene.config.height, Path_Statistics, alignment=CACHE_LINE_SIZE);
}

prepare_for_rendering :: (scene: *Scene)
{
    scene.camera.aspect_ratio = scene.config.width.(float) / scene.config.height.(float);
    UpdateCameraParams(*scene.camera);
    build_bvh(scene);
}

build_bvh :: (scene: *Scene)
{
    if scene.primitives.count
    {
        array_resize(*scene.bboxes, scene.primitives.count, initialize=false);
        array_resize(*scene.tlas.indices, scene.primitives.count, initialize=false);
        array_resize(*scene.tlas.nodes, 2 * scene.primitives.count - 1);

        array_resize(*scene.mapped, scene.primitives.count, initialize=false);

        for scene.primitives
        {
            bbox: Box3 = ---;

            if #complete it.type ==
            {
                case .SPHERE;
                    radius    := it.shape.sphere.radius;
                    center    := transform_point(it.xform.forward, Vector3.{0, 0, 0});
                    bbox.vmin  = center - Vector3.{radius, radius, radius};
                    bbox.vmax  = center + Vector3.{radius, radius, radius};

                case .DISK;
                    radius := it.shape.disk.radius;
                    center := transform_point(it.xform.forward, Vector3.{0, 0, 0});
                    bbox    = bounding_box_from_points(center - Vector3.{radius, radius, 0}, center + Vector3.{radius, radius, 0});
                    bbox    = pad_to_minimus(bbox, 0.0001);

                case .BOX;
                    bbox = transform_box(it.xform.forward, Box3.{it.shape.box.vmin, it.shape.box.vmax});

                case .MESH;
                    bbox = Box3_Empty;
                    for v: it.shape.mesh.vertices
                    {
                        p := transform_point(it.xform.forward, v.p);
                        bbox = box_union(bbox, p);
                    }
            }

            scene.bboxes[it_index] = bbox;
        }

        for *scene.tlas.indices
        {
            it.* = it_index.(u32);
        }

        build_bvh_binned_sah(scene.tlas.nodes, scene.tlas.indices, scene.bboxes);

        for scene.tlas.indices
        {
            scene.mapped[it_index] = scene.primitives[it];
        }
    }
}

half_area :: (b: Box3) -> float
{
    d := b.vmax - b.vmin;
    res := (d.x * d.y + d.x * d.z + d.y * d.z);
    return res;
}

UpdateCameraParams :: (camera: *Camera)
{
    rotation := Matrix4_Identity;
    set_rotation(*rotation, camera.orientation);
    camera.xform = make_translation_matrix4(camera.position) * rotation;
    h           := tan(camera.fov * PI);
    camera.dxdu  = .{h * camera.aspect_ratio, 0, 0};
    camera.dydv  = .{0, h, 0};

    // generate filter
    width := camera.filter.width;
    if camera.filter.type == .BLACKMAN_HARRIS
    {
        width *= 2.0;
    }

    cdf: [FILTER_SIZE + 1]float;
    EvaluateFilterCDF(cdf, 0.0, width * 0.5, camera.filter.type, width);
    InvertCDF(camera.filter_lut, cdf, 0.0, width * 0.5);
}

generate_ray :: (pixel: Vector2, camera: Camera, lens_uv: Vector2) -> Ray
{
    origin := Vector3.{0, 0, 0};
    target := Vector3.{0, 0, 1};

    if #complete camera.type ==
    {
        case .PERSPECTIVE;
            origin = Vector3.{0, 0, 0};
            target = pixel.x * camera.dxdu + pixel.y * camera.dydv + Vector3.{0, 0, 1};

        case .ORTHOGRAPHIC;
            origin = pixel.x * camera.dxdu + pixel.y * camera.dydv;
            target = origin + Vector3.{0, 0, 1};
    }

    if camera.lens_radius > 0.0
    {
        origin.xy = camera.lens_radius * sample_uniform_disk_polar(lens_uv);
        dir   := normalize(target - origin);
        ft    := camera.lens_focal_length / dir.z;
        focus := ft * dir;
        target = focus;
    }

    origin = transform_point(camera.xform, origin);
    target = transform_point(camera.xform, target);

    ray: Ray = ---;

    ray.origin = origin;
    ray.dir    = normalize(target - origin);
    ray.tmin   = 0.0;
    ray.tmax   = FLOAT32_INFINITY;

    return ray;
}

sample_stratified_square :: (x: float, y: float, inv_size: float) -> Vector2
{
    px := x + random_get_zero_to_one_open();
    py := y + random_get_zero_to_one_open();

    px *= inv_size;
    py *= inv_size;

    return .{px, py};
}

bounding_box_from_points :: (a : Vector3, b: Vector3) -> Box3
{
    minp := min(a, b);
    maxp := max(a, b);
    return Box3.{minp, maxp};
}

pad_to_minimus :: (b: Box3, padding: float) -> Box3
{
    r := b;
    if (r.vmax.x - r.vmin.x < padding)
    {
        r.vmin.x -= padding;
        r.vmax.x += padding;
    }
    if (r.vmax.y - r.vmin.y < padding)
    {
        r.vmin.y -= padding;
        r.vmax.y += padding;
    }
    if (r.vmax.z - r.vmin.z < padding)
    {
        r.vmin.z -= padding;
        r.vmax.z += padding;
    }
    return r;
}

// @todo: Multithread
radix_sort :: (K: []u32, K_temp: []u32, V: []$T, V_temp: []T, n: s64)
{
    prefix: [256]u32;

    for 0..3
    {
        memset(prefix.data, 0, size_of(type_of(prefix)));

        shift := it * 8;
        for 0..n-1
        {
            bin_index := ((K[it] >> shift) & 0xFF);
            assert(bin_index < prefix.count);
            prefix[bin_index] += 1;
        }

        prev_sum : u32 = 0;

        for 0..prefix.count-1
        {
            sum := prefix[it] + prev_sum;
            prefix[it] = prev_sum;
            prev_sum = sum;
        }

        for 0..n-1
        {
            bin_index := ((K[it] >> shift) & 0xFF);
            offset := prefix[bin_index];
            K_temp[offset] = K[it];
            V_temp[offset] = V[it];
            prefix[bin_index] += 1;
        }

        Swap(*K, *K_temp);
        Swap(*V, *V_temp);
    }
}

triangle_bbox :: (p: Vector3, q: Vector3, r: Vector3) -> Box3
{
    bbox := Box3_Empty;
    bbox = box_union(bbox, p);
    bbox = box_union(bbox, q);
    bbox = box_union(bbox, r);
    return bbox;
}

// https://fgiesen.wordpress.com/2009/12/13/decoding-morton-codes/

encode_morton2 :: (x: u32, y: u32) -> u32
{
    x_split := split2(x);
    y_split := split2(y);
    code    := (y_split << 1) | x_split;
    return code;
}

split3 :: (x: u32) -> u32
{
    x &= 0x000003ff;
    x = (x ^ (x << 16)) & 0xFF0000FF;
    x = (x ^ (x <<  8)) & 0x0300F00F;
    x = (x ^ (x <<  4)) & 0x030C30C3;
    x = (x ^ (x <<  2)) & 0x09249249;
    return x;
}

encode_morton3 :: (x: u32, y: u32, z: u32) -> u32
{
    x_split := split3(x);
    y_split := split3(y);
    z_split := split3(z);
    code    := (z_split << 2) | (y_split << 1) | x_split;
    return code;
}

SAHBuilder :: struct
{
    nodes     : []BVH_Node;
    next_node : u32;
}

build_bvh_sah_binned_recursive :: (builder: *SAHBuilder, root: u32, lo: s64, hi: s64, indices: []u32, bboxes: []Box3, centriods: []Vector3)
{
    assert(hi >= lo);

    node := *builder.nodes[root];

    if (hi == lo)
    {
        node.bbox                     = bboxes[indices[lo]];
        node.first_child_or_primitive = lo.(u32);
        node.num_primitives           = 1;
        return;
    }

    node_bbox     := Box3_Empty;
    centriod_bbox := Box3_Empty;

    for lo..hi
    {
        node_bbox     = box_union(node_bbox, bboxes[indices[it]]);
        centriod_bbox = box_union(centriod_bbox, centriods[indices[it]]);
    }

    split_axis := 0;
    max_delta  := centriod_bbox.vmax.component[0] - centriod_bbox.vmin.component[0];

    for 1..2
    {
        delta := centriod_bbox.vmax.component[it] - centriod_bbox.vmin.component[it];
        if delta > max_delta
        {
            max_delta = delta;
            split_axis = it;
        }
    }

    if max_delta <= FLOAT_EPS || half_area(node_bbox) <= FLOAT_EPS
    {
        node.bbox                     = node_bbox;
        node.first_child_or_primitive = lo.(u32);
        node.num_primitives           = (hi - lo + 1).(u32);
        return;
    }

    BIN_COUNT   :: 16;
    SPLIT_COUNT :: BIN_COUNT - 1;

    Bin :: struct
    {
        count: s64;
        bbox : Box3;
    }

    bins: [BIN_COUNT]Bin;

    for *bins
    {
        it.count = 0;
        it.bbox = Box3_Empty;
    }

    idelta := 1.0 / max_delta;
    offset := centriod_bbox.vmin.component[split_axis];

    find_bin_index :: (centriod: Vector3) -> int #expand
    {
        bin_index := (BIN_COUNT * (centriod.component[split_axis] - offset) * idelta).(s64);
        if bin_index >= BIN_COUNT then
            bin_index = BIN_COUNT - 1;
        return bin_index;
    }

    for lo..hi
    {
        bin_index := find_bin_index(centriods[indices[it]]);
        bins[bin_index].count += 1;
        bins[bin_index].bbox = box_union(bins[bin_index].bbox, bboxes[indices[it]]);
    }

    split_costs: [SPLIT_COUNT]float;

    prev_count := 0;
    prev_box   := Box3_Empty;

    for 0..SPLIT_COUNT-1
    {
        prev_box = box_union(prev_box, bins[it].bbox);
        prev_count += bins[it].count;
        split_costs[it] += prev_count * half_area(prev_box);
    }

    prev_count = 0;
    prev_box   = Box3_Empty;

    for #v2 < 1..SPLIT_COUNT
    {
        prev_box = box_union(prev_box, bins[it].bbox);
        prev_count += bins[it].count;
        split_costs[it - 1] += prev_count * half_area(prev_box);
    }

    min_split_cost := split_costs[0];
    min_split_cost_index := 0;

    for 1..SPLIT_COUNT-1
    {
        if (split_costs[it] < min_split_cost)
        {
            min_split_cost = split_costs[it];
            min_split_cost_index = it;
        }
    }

    split_cost  := 0.5 + min_split_cost / half_area(node_bbox);
    leaves_cost := (hi - lo + 1).(float);

    if (split_cost > leaves_cost)
    {
        node.bbox                     = node_bbox;
        node.first_child_or_primitive = lo.(u32);
        node.num_primitives           = (hi - lo + 1).(u32);
        return;
    }

    // partition
    mid := -1;

    {
        i := lo - 1;
        j := hi + 1;

        while 1
        {
            i += 1;

            while i <= hi
            {
                bin_index := find_bin_index(centriods[indices[i]]);
                if bin_index > min_split_cost_index
                    break;
                i += 1;
            }

            j -= 1;

            while j >= lo
            {
                bin_index := find_bin_index(centriods[indices[j]]);
                if bin_index <= min_split_cost_index
                    break;
                j -= 1;
            }

            if i >= j
            {
                mid = j;
                break;
            }

            swap(*indices[j], *indices[i]);
        }
    }

    assert(mid >= lo && mid < hi);

    next := builder.next_node;
    builder.next_node += 2;

    build_bvh_sah_binned_recursive(builder, next + 0, lo, mid, indices, bboxes, centriods);
    build_bvh_sah_binned_recursive(builder, next + 1, mid + 1, hi, indices, bboxes, centriods);

    node.bbox                     = box_union(builder.nodes[next + 0].bbox, builder.nodes[next + 1].bbox);
    node.first_child_or_primitive = next;
    node.num_primitives           = 0;
}

build_bvh_binned_sah :: (nodes: []BVH_Node, indices: []u32, bboxes: []Box3)
{
    assert(nodes.count == bboxes.count * 2 - 1 && indices.count == bboxes.count);

    auto_release_temp();

    centriods := NewArray(bboxes.count, Vector3, initialized=false,, temp);

    for bboxes
    {
        centriods[it_index] = 0.5 * (it.vmin + it.vmax);
    }

    builder := SAHBuilder.{nodes, 1};
    build_bvh_sah_binned_recursive(*builder, 0, 0, indices.count - 1, indices, bboxes, centriods);
}

build_blas :: (mesh: *Primitive_Mesh)
{    
    num_triangles := mesh.indices.count / 3;

    // @todo: cleanup
    bboxes: []Box3;
    defer array_free(bboxes);

    array_resize(*bboxes, num_triangles, initialize=false);
    array_resize(*mesh.blas.indices, num_triangles, initialize=false);
    array_resize(*mesh.blas.nodes, 2 * num_triangles - 1, initialize=false);

    for 0..num_triangles-1
    {
        i0 := mesh.indices[it * 3 + 0];
        i1 := mesh.indices[it * 3 + 1];
        i2 := mesh.indices[it * 3 + 2];

        v0 := mesh.vertices[i0].p;
        v1 := mesh.vertices[i1].p;
        v2 := mesh.vertices[i2].p;

        bboxes[it]  = triangle_bbox(v0, v1, v2);
        mesh.blas.indices[it] = it.(u32);
    }

    // @todo: map indices or may be not worth it??
    build_bvh_binned_sah(mesh.blas.nodes, mesh.blas.indices, bboxes);
}

sign_of :: (v: float) -> float
{
    return ((0 < v).(float) - (v < 0).(float));
}

orthonormal_basis :: (x_axis: Vector3) -> (y_axis: Vector3, z_axis: Vector3)
{
    cross := Vector3.{1, 1, 1};
    if x_axis.x > x_axis.y
    {
        if x_axis.x > x_axis.z
        {
            cross.x = 0;
        }
        else
        {
            cross.z = 0;
        }
    }
    else
    {
        if x_axis.y > x_axis.z
        {
            cross.y = 0;
        }
        else
        {
            cross.z = 0;
        }
    }

    y_axis := cross_product(cross, x_axis);
    normalize(*y_axis, fallback=.{z=1});

    z_axis := cross_product(x_axis, y_axis);
    normalize(*z_axis, fallback=.{z=1});

    return y_axis, z_axis;
}

load_obj_model :: (path: string) -> Primitive_Mesh
{
    auto_release_temp();

    content := read_entire_file(path,,temp);

    vertices  : [..]Vector3;
    normals   : [..]Vector3;
    texcoords : [..]Vector2;

    vertex_indices   : [..]u32;
    normal_indices   : [..]u32;
    texcoord_indices : [..]u32;

    // @todo @cleanup
    // Use Xar or temporary memory/arena
    defer
    {
        array_free(vertices);
        array_free(normals);
        array_free(texcoords);
        array_free(vertex_indices);
        array_free(normal_indices);
        array_free(texcoord_indices);
    }

    while content
    {
        found:, line:, content = split_from_left(content, #char "\n");
        if !found break;

        if starts_with(line, "v ")
        {
            v: Vector3;
            scan2(line, "v % % %", *v.x, *v.y, *v.z);
            array_add(*vertices, v);
        }
        else if starts_with(line, "vt ")
        {
            uv: Vector2;
            scan2(line, "vt % %", *uv.x, *uv.y);
            array_add(*texcoords, uv);
        }
        else if starts_with(line, "vn ")
        {
            n: Vector3;
            scan2(line, "vn % % %", *n.x, *n.y, *n.z);
            array_add(*normals, n);
        }
        else if starts_with(line, "f ")
        {
            parse_face :: (line: string) #expand
            {
                number, success, face := string_to_int(line, T=s32);
                index := ifx number > 0 then (number - 1).(u32) else (vertices.count + number).(u32);
                array_add(*vertex_indices, index);

                if !face return;
                face = slice(face, 1, face.count - 1);

                number, success, face = string_to_int(face, T=s32);
                if success
                {
                    index = ifx number > 0 then (number - 1).(u32) else (texcoords.count + number).(u32);
                    array_add(*texcoord_indices, index);
                }

                if !face return;
                face = slice(face, 1, face.count - 1);

                number, success, face = string_to_int(face, T=s32);
                if success
                {
                    index = ifx number > 0 then (number - 1).(u32) else (normals.count + number).(u32);
                    array_add(*normal_indices, index);
                }
            }

            face1, face2, face3 : string;
            found, line, face3 = split_from_right(line, #char " ");
            found, line, face2 = split_from_right(line, #char " ");
            found, line, face1 = split_from_right(line, #char " ");

            parse_face(face1);
            parse_face(face2);
            parse_face(face3);
        }
    }

    AttrIndex :: struct
    {
        vertex_index   : u32;
        normal_index   : u32;
        texcoord_index : u32;
    }

    hash_attr_index :: (a: AttrIndex) -> u32
    {
        return sdbm_hash((*a).(*void), size_of(AttrIndex));
    }

    compare_attr_index :: (a: AttrIndex, b: AttrIndex) -> bool
    {
        return a.vertex_index == b.vertex_index && a.normal_index == b.normal_index && a.texcoord_index == b.texcoord_index;
    }

    map   : Table(AttrIndex, u32, given_hash_function=hash_attr_index, given_compare_function=compare_attr_index, REFILL_REMOVED=false);
    attrs := NewArray(vertex_indices.count, Vertex3 ,,temp);

    defer deinit(*map); // @todo: Use temporary memory

    indices := NewArray(vertex_indices.count, u32);

    num_attrs := 0;

    for 0..vertex_indices.count-1
    {
        index: AttrIndex;
        index.vertex_index   = vertex_indices[it];
        index.texcoord_index = ifx texcoord_indices texcoord_indices[it] else 0;
        index.normal_index   = ifx normal_indices normal_indices[it] else 0;

        entry, added := find_or_add(*map, index);

        if added
        {
            entry.* = num_attrs.(u32);
            attrs[num_attrs].p  = vertices[index.vertex_index];
            if texcoords
                attrs[num_attrs].uv = texcoords[index.texcoord_index];
            if normals
                attrs[num_attrs].n  = normals[index.normal_index];
            attrs[num_attrs].t = Vector3.{0, 0, 0};
            attrs[num_attrs].b = Vector3.{0, 0, 0};
            num_attrs += 1;
        }

        indices[it] = entry.*;
    }

    mesh: Primitive_Mesh;

    mesh.vertices = array_copy(array_view(attrs, 0, num_attrs));
    mesh.indices  = indices;

    num_triangles := indices.count / 3;

    if !normals
    {
        for 0..num_triangles-1
        {
            v0 := *mesh.vertices[indices[it * 3 + 0]];
            v1 := *mesh.vertices[indices[it * 3 + 1]];
            v2 := *mesh.vertices[indices[it * 3 + 2]];

            e1 := v1.p - v0.p;
            e2 := v2.p - v0.p;

            n  := cross_product(e1, e2);
            n   = normalize(n);

            v0.n = n;
            v1.n = n;
            v2.n = n;
        }
    }

    num_triangles_included := NewArray(num_attrs, u32,,temp);

    for 0..num_triangles-1
    {
        i0 := indices[it * 3 + 0];
        i1 := indices[it * 3 + 1];
        i2 := indices[it * 3 + 2];

        v0 := *mesh.vertices[i0];
        v1 := *mesh.vertices[i1];
        v2 := *mesh.vertices[i2];

        delta_uv1 := v1.uv - v0.uv;
        delta_uv2 := v2.uv - v0.uv;
        det       := delta_uv1.x * delta_uv2.y - delta_uv1.y * delta_uv2.x;
        degen     := abs(det) == 0.0;

        tangent, bitangent : Vector3;

        if (!degen)
        {
            inv_det  := 1.0 / det;
            delta_p1 := v1.p - v0.p;
            delta_p2 := v2.p - v0.p;
            tangent = (delta_p1 * delta_uv2.y - delta_p2 * delta_uv1.y) * inv_det;
            bitangent = (delta_p2 * delta_uv1.x - delta_p1 * delta_uv2.x) * inv_det;
        }

        if (degen || length_squared(cross(tangent, bitangent)) == 0.0)
        {
            normal := normalize((v0.n + v1.n + v2.n) / 3);
            tangent, bitangent = orthonormal_basis(normal);
        }

        v0.t += tangent;
        v1.t += tangent;
        v2.t += tangent;

        v0.b += bitangent;
        v1.b += bitangent;
        v2.b += bitangent;

        num_triangles_included[i0] += 1;
        num_triangles_included[i1] += 1;
        num_triangles_included[i2] += 1;
    }

    for 0..mesh.vertices.count-1
    {
        v := *mesh.vertices[it];

        v.t /= num_triangles_included[it].(float);
        v.b /= num_triangles_included[it].(float);

        v.t = normalize(v.t - v.n * dot(v.t, v.n));
        handedness := ifx (dot(cross(v.n, v.t), v.b) < 0.0) then -1.0 else 1.0;
        v.b = cross(v.n, v.t) * handedness;
    }

    build_blas(*mesh);

    return mesh;
}

CommandLineArgs :: struct
{
    width       := 1920;
    height      := 1080;
    scene       := SceneType.material_test;
    save_first  := false;
    num_threads := 0;
}

#load "noise.jai";

Display_Type :: enum
{
    RENDER;
    BOUNCE_HEATMAP;
    BVH_VISIT_HEATMAP;
}

main :: ()
{
    //compute_metallic_lookup_tables(true);

    init();

    success, args := parse_arguments(CommandLineArgs);

    print("args = %\n", args);

    if (args.save_first)
    {
        want_screenshot = true;
    }

    // test code
  //  N :: 200000;
  //  errors : [..]float;
  //  roughness := 0.7;

  //  V := Vector3.{0, 0, 1};

  //  for 0..N
  //  {
    //      u1 := random_get_zero_to_one_open();
    //      u2 := random_get_zero_to_one_open();
  //      sample := cltc_sample(V, roughness, u1, u2);
  //      pdf_a  := cltc_pdf(V, sample.L, roughness);
  //      array_add(*errors, (sample.pdf - pdf_a) / max(pdf_a, 1.0e-9));
  //  }

  //  mean := 0.0;
  //  for errors
  //  {
  //      mean += it * it;
  //  }
  //  mean /= errors.count.(float);
  //  print("RMS : %\n", sqrt(mean));

    MSAA :: 8;

    render_width  = args.width;
    render_height = args.height;

    wnd := create_window(render_width, render_height, "PixL", wanted_msaa = MSAA);

    init_fonts();

    scene: Scene;
    init_scene(*scene, RAYTRACE_BITMAP_WIDTH, RAYTRACE_BITMAP_HEIGHT, multisamples=16, max_depth=5);
    load_scene(*scene, args.scene);

    prepare_for_rendering(*scene);

    wave: Thread_Wave;
    thread_wave_start(*wave, wavefront_raytrace_entry, shared = *scene, used_threads = 4);

    Simp.prepare_window(wnd, wanted_msaa = MSAA);

    Simp.set_render_target(wnd, .RIGHT_HANDED);

    raytrace_map : Simp.Texture;

    while !should_quit
    {
        memory_visualizer_per_frame_update();

        update_window_events();

        for get_window_resizes()
        {
            Simp.update_window(it.window);

            if it.window == wnd
            {
                should_reinit := (it.width != render_width) || (it.height != render_height);

                render_width  = it.width;
                render_height = it.height;

                if should_reinit then
                    init_fonts();
            }
        }

        for events_this_frame
        {
            if it.type == .QUIT then should_quit = true;

            if it.type ==
            {
              case .KEYBOARD;
                if it.key_pressed && it.key_code == .ESCAPE
                {
                    should_quit = true;
                }

                if it.key_pressed && it.key_code == #char "Z"
                {
                    info := type_info(Display_Type);
                    display_type = ((display_type + 1).(u32) % info.values.count).(Display_Type);
                }

                if it.key_pressed && it.key_code == #char "H"
                {
                    show_debug_bvh = !show_debug_bvh;
                }

                if it.key_pressed && it.key_code == .TAB
                {
                    show_random_test = !show_random_test;
                }

                
                if it.key_pressed && it.key_code == .ARROW_RIGHT
                {
                    num_samples_to_display = (num_samples_to_display + 1) % NUM_RANDOM_SAMPLES;
                }

                if it.key_pressed && it.key_code == .ARROW_LEFT
                {
                    num_samples_to_display = (num_samples_to_display - 1 + NUM_RANDOM_SAMPLES) % NUM_RANDOM_SAMPLES;
                }

                if it.key_pressed && it.key_code == #char " "
                {
                    want_screenshot = true;
                }

                if it.key_pressed && it.key_code == #char "."
                {
                    debug_bvh_depth += 1;
                    if debug_bvh_depth > 255 debug_bvh_depth = 255;
                    print("debug_bvh_depth : %\n", debug_bvh_depth);
                }

                if it.key_pressed && it.key_code == #char ","
                {
                    debug_bvh_depth -= 1;
                    if debug_bvh_depth < 0 debug_bvh_depth = 0;
                    print("debug_bvh_depth : %\n", debug_bvh_depth);
                }
            }
        }

        display_bitmap := *scene.bitmap;

        if (!white_furnace_test_enabled)
        {
            if display_type == 
            {
                case .BOUNCE_HEATMAP;
                    display_bitmap = *scene.bounces_heatmap;
                case .BVH_VISIT_HEATMAP;
                    display_bitmap = *scene.bvh_visits_heatmap;
            }
        }

        Simp.texture_load_from_bitmap(*raytrace_map, display_bitmap);
        draw_one_frame(wnd, *raytrace_map, scene, wave.threads.count);

        sleep_milliseconds(10);

        reset_temporary_storage();
    }

    thread_wave_join(*wave);
}

save_screenshot :: (bitmap: Bitmap, screenshot_index: *int)
{
    filepath := tprint("captures/screenshot_%.png", screenshot_index.*);
    print("Saving screenshot: %\n", filepath);
    if (Simp.bitmap_save(*bitmap, filepath))
        screenshot_index.* += 1;
}

draw_rect :: (center: Vector2, w: Vector2, h: Vector2, color: Vector4)
{
    p0 := center - w - h;
    p1 := center + w - h;
    p2 := center + w + h;
    p3 := center - w + h;
    Simp.immediate_quad(p0, p1, p2, p3, color, color, color, color);
}

emboss_line :: (p0: Vector2, p1: Vector2, stroke: float) -> [4]Vector2
{
    corners: [4]Vector2 = ---;
    dx := p1.x - p0.x;
    dy := p1.y - p0.y;
    normal := normalize(Vector2.{-dy, dx});
    corners[0] = p0 - stroke * normal;
    corners[1] = p0 + stroke * normal;
    corners[2] = p1 + stroke * normal;
    corners[3] = p1 - stroke * normal;
    return corners;
}

draw_line :: (a: Vector3, b: Vector3, color: Vector4, projection: Matrix4)
{
    p0 := projection * Vector4.{ a.x, a.y, a.z, 1 };
    p1 := projection * Vector4.{ b.x, b.y, b.z, 1 };

    p0 /= p0.w;
    p1 /= p1.w;

    p0.x *= MAP_RATIO;
    p0.y *= MAP_RATIO;

    p1.x *= MAP_RATIO;
    p1.y *= MAP_RATIO;

    p0 *= 0.5;
    p1 *= 0.5;

    p0 += Vector4.{ 0.5, 0.5, 0.5, 0.5 };
    p1 += Vector4.{ 0.5, 0.5, 0.5, 0.5 };

    p0.x *= (render_width - 1);
    p0.y *= (render_height - 1);
    p1.x *= (render_width - 1);
    p1.y *= (render_height - 1);

    corners := emboss_line(p0.xy, p1.xy, 1);

    Simp.immediate_quad(corners[0], corners[1], corners[2], corners[3], color, color, color, color);
}

draw_triangle :: (v0: Vertex3, v1: Vertex3, v2: Vertex3, color: Vector4, pv: Matrix4, inv_transpose: Matrix4)
{
    light_dir := Vector3.{0, -1, 1};

    light_dir = normalize(light_dir);

    strength1 := max(dot(v0.n, -light_dir), 0.0);
    strength2 := max(dot(v1.n, -light_dir), 0.0);
    strength3 := max(dot(v2.n, -light_dir), 0.0);

    color1 := strength1 * color;
    color2 := strength2 * color;
    color3 := strength3 * color;

    p0 := pv * Vector4.{ v0.p.x, v0.p.y, v0.p.z, 1 };
    p1 := pv * Vector4.{ v1.p.x, v1.p.y, v1.p.z, 1 };
    p2 := pv * Vector4.{ v2.p.x, v2.p.y, v2.p.z, 1 };

    p0 /= p0.w;
    p1 /= p1.w;
    p2 /= p2.w;

    p0.x *= MAP_RATIO;
    p0.y *= MAP_RATIO;

    p1.x *= MAP_RATIO;
    p1.y *= MAP_RATIO;

    p2.x *= MAP_RATIO;
    p2.y *= MAP_RATIO;

    p0 *= 0.5;
    p1 *= 0.5;
    p2 *= 0.5;

    p0 += Vector4.{ 0.5, 0.5, 0.5, 0.0 };
    p1 += Vector4.{ 0.5, 0.5, 0.5, 0.0 };
    p2 += Vector4.{ 0.5, 0.5, 0.5, 0.0 };

    face := cross(p1.xyz - p0.xyz, p2.xyz - p0.xyz);

    if face.z >= 0 then
        return;

    p0.x *= (render_width - 1);
    p0.y *= (render_height - 1);
    p1.x *= (render_width - 1);
    p1.y *= (render_height - 1);
    p2.x *= (render_width - 1);
    p2.y *= (render_height - 1);

    Simp.immediate_triangle(p0.xyz, p1.xyz, p2.xyz, color1, color2, color3);

    //draw_line(v0.p, v1.p, color, projection);
    //draw_line(v1.p, v2.p, color, projection);
    //draw_line(v2.p, v0.p, color, projection);
}

draw_mesh :: (mesh: Primitive_Mesh, color: Vector4, pv: Matrix4, inv_transpose: Matrix4)
{
    num_triangles := mesh.indices.count / 3;

    for 0..num_triangles-1
    {
        i0 := mesh.indices[it * 3 + 0];
        i1 := mesh.indices[it * 3 + 1];
        i2 := mesh.indices[it * 3 + 2];
        draw_triangle(mesh.vertices[i0], mesh.vertices[i1], mesh.vertices[i2], color, pv, inv_transpose);
    }
}

draw_box :: (box: Box3, color: Vector4, projection: Matrix4)
{
    diag := box.vmax - box.vmin;

    dx := Vector3.{diag.x, 0, 0};
    dy := Vector3.{0, diag.y, 0};
    dz := Vector3.{0, 0, diag.z};

    draw_line(box.vmin, box.vmin + dx, color, projection);
    draw_line(box.vmin, box.vmin + dy, color, projection);
    draw_line(box.vmin, box.vmin + dz, color, projection);
    draw_line(box.vmin + dz, box.vmin + dz + dx, color, projection);
    draw_line(box.vmin + dz, box.vmin + dz + dy, color, projection);
    draw_line(box.vmin + dx, box.vmin + dx + dz, color, projection);
    draw_line(box.vmin + dx, box.vmin + dx + dy, color, projection);
    draw_line(box.vmin + dy, box.vmin + dy + dx, color, projection);
    draw_line(box.vmin + dy, box.vmin + dy + dz, color, projection);
    draw_line(box.vmin + dx + dz, box.vmin + dx + dz + dy, color, projection);
    draw_line(box.vmin + dx + dy, box.vmin + dx + dy + dz, color, projection);
    draw_line(box.vmin + dy + dz, box.vmin + dy + dz + dx, color, projection);
}

draw_bvh :: (root: int, nodes: []BVH_Node, boxes: []Box3, indices: []u32, projection: Matrix4, depth: int)
{
    using node := nodes[root];

    if num_primitives
    {
        if depth == debug_bvh_depth || debug_bvh_depth == -1
        {
            for 0..num_primitives-1
            {
                index := indices[it + first_child_or_primitive];
                draw_box(boxes[index], Vector4.{1, 1, 1, 1}, projection);
            }
        }
    }
    else
    {
        if depth == debug_bvh_depth || debug_bvh_depth == -1
            draw_box(bbox, Vector4.{1, 1, 1, 1}, projection);

        draw_bvh(first_child_or_primitive + 0, nodes, boxes, indices, projection, depth + 1);
        draw_bvh(first_child_or_primitive + 1, nodes, boxes, indices, projection, depth + 1);
    }
}

//------------------------------------------------------------------------

SAMPLES_PER_AXIS   :: 128;
NUM_RANDOM_SAMPLES :: SAMPLES_PER_AXIS * SAMPLES_PER_AXIS;

num_samples_to_display := NUM_RANDOM_SAMPLES - 1;

pcg_random_samples:      [NUM_RANDOM_SAMPLES]Vector2;
sobol_random_samples:    [NUM_RANDOM_SAMPLES]Vector2;
sobol_ss_random_samples: [NUM_RANDOM_SAMPLES]Vector2;

initted_random_samples := false;
show_random_test := false;

InitializeRandomSamples :: ()
{
    for * pcg_random_samples
    {
        x := random_get_zero_to_one_open();
        y := random_get_zero_to_one_open();
        it.* = .{x, y};
    }

    seed : u32 = 7777;

    for * sobol_random_samples
    {
        x := sample_sobol(it_index.(u32), 0);
        y := sample_sobol(it_index.(u32), 1);
        it.* = .{x, y};
    }

    for * sobol_ss_random_samples
    {
        x   := it_index % SAMPLES_PER_AXIS;
        y   := it_index / SAMPLES_PER_AXIS;
        rng := path_random_state(x.(u32), y.(u32), 0, 1, seed);
        p   := random_sample_2D(rng, .FILTER);
        it.* = p;
    }
}

DrawRect :: (corner: Vector2, width: float, height: float, color: Vector4)
{
    w  := Vector2.{width / 2, 0};
    h  := Vector2.{0, height / 2};
    center := corner + w + h;
    p0 := center - w - h;
    p1 := center + w - h;
    p2 := center + w + h;
    p3 := center - w + h;
    Simp.immediate_quad(p0, p1, p2, p3, color, color, color, color);
}

draw_random_test :: ()
{
    if !initted_random_samples
    {
        InitializeRandomSamples();
        initted_random_samples = true;
    }

    size := 600.0;
    gap  := 50.0;

    x    := 0.5 * (render_width.(float) - size * 3 - 2 * gap);
    y    := 0.5 * (render_height.(float) - size);

    corner := Vector2.{x, y};

    DrawRect(corner, size, size, .{1, 1, 1, 1});

    for 0..num_samples_to_display
    {
        r := pcg_random_samples[it];
        p := corner + r * size;
        DrawRect(p, 2, 2, .{0, 0, 0, 1});
    }

    corner.x += size + gap;
    DrawRect(corner, size, size, .{1, 1, 1, 1});

    for 0..num_samples_to_display
    {
        r := sobol_random_samples[it];
        p := corner + r * size;
        DrawRect(p, 2, 2, .{0, 0, 0, 1});
    }

    corner.x += size + gap;
    DrawRect(corner, size, size, .{1, 1, 1, 1});

    for 0..num_samples_to_display
    {
        r := sobol_ss_random_samples[it];
        p := corner + r * size;
        DrawRect(p, 2, 2, .{0, 0, 0, 1});
    }
}

draw_one_frame :: (wnd: Window_Type, map: *Simp.Texture, scene: Scene, num_threads: int)
{
    time := seconds_since_init();

    Simp.clear_render_target(.15, .08, .08, 1);

    Simp.set_shader_for_images(map);

    {
        aspect_ratio := RAYTRACE_BITMAP_WIDTH.(float) / RAYTRACE_BITMAP_HEIGHT.(float);

        rect_height := render_height.(float) * MAP_RATIO;
        rect_width := aspect_ratio * rect_height;

        center: Vector2;
        center.x = render_width.(float) / 2;
        center.y = render_height.(float) / 2;

        w := Vector2.{rect_width / 2, 0};
        h := Vector2.{0, rect_height / 2};

        p0 := center - w - h;
        p1 := center + w - h;
        p2 := center + w + h;
        p3 := center - w + h;

        white : = Vector4.{ 1, 1, 1, 1 };
        
        Simp.immediate_quad(p0, p1, p2, p3, white, white, white, white);
    }

    Simp.set_shader_for_color();

    if (show_random_test)
    {
        draw_random_test();
    }

    if show_debug_bvh
    {
        //projection_view := scene.camera.xform.projection * scene.camera.xform.view * debug_mesh_xform;
        //draw_bvh(0, scene.tlas.nodes, scene.tlas.bboxes, scene.tlas.indices, projection_view, 0);
        //draw_bvh(0, debug_mesh.blas.nodes, debug_mesh.blas.bboxes, debug_mesh.blas.indices, projection_view, 0);

        //_, inv := inverse(scene.camera.xform.view * debug_mesh_xform);
        //inv_transpose := transpose(inv);

        //draw_mesh(debug_mesh, .{1, 1, 1, 1}, projection_view, inv_transpose);
    }

    secs  := time.(int);
    mins  := secs / 60;
    secs   = secs % 60;
    hours := mins / 60;
    mins   = mins % 60;

    total_runtime := tprint("%:%:%",
                            formatInt(hours, minimum_digits=2),
                            formatInt(mins, minimum_digits=2),
                            formatInt(secs, minimum_digits=2));

    if (white_furnace_test_enabled)
    {
        text := tprint("Frame: %; Last frame render time: %ms; Threads: %; Runtime: %; White Furnace Test dE = %\%, bias = %\%, max error = %",
                       frame_index, last_frame_render_time_ms, num_threads, total_runtime,
                       white_furnace_test_error * 100, white_furnace_test_bias * 100, white_furnace_test_max_error);
        Simp.draw_text(debug_font, 10, 10, text);
    }
    else
    {
        text := tprint("Frame: %; Last frame render time: %ms; Threads: %; Runtime: %; Bitmap: %",
                       frame_index, last_frame_render_time_ms, num_threads, total_runtime, display_type);
        Simp.draw_text(debug_font, 10, 10, text);
    }

    Simp.swap_buffers(wnd);
}

MAP_RATIO :: 0.9;

debug_bvh_depth := -1;
show_debug_bvh := false;
should_quit := false;
render_width := 0;
render_height := 0;

frame_index := 0;
last_frame_render_time_ms := 0;
display_type := Display_Type.RENDER;

debug_font: *Simp.Dynamic_Font;

init_fonts :: ()
{
    if render_height <= 0 then return;

    pixel_height := render_height / 54;

    debug_font = Simp.get_font_at_size("data/fonts/KodeMono", "KodeMono-Medium.ttf", pixel_height);
    assert(debug_font != null);
}

find_next_screenshot_index :: (info: *File_Visit_Info, user_data: *void)
{
    screenshot_index := user_data.(*int);
    prefix := "screenshot_";

    if (starts_with(info.short_name, prefix))
    {
        postfix := slice(info.short_name, prefix.count, info.short_name.count - prefix.count);

        postfix_number, success, _ := to_integer(postfix);
        if success && postfix_number > screenshot_index.* then
            screenshot_index.* = postfix_number;
    }
}

get_first_screenshot_index :: (path: string) -> int
{
    screenshot_index := 0;
    make_directory_if_it_does_not_exist(path);
    visit_files(path, false, (*screenshot_index).(*void), find_next_screenshot_index);
    return screenshot_index + 1;
}

init :: ()
{
    #if OS == .WINDOWS
    {
        Windows :: #import "Windows";
        Windows.SetProcessDPIAware();
        Windows.timeBeginPeriod(1);
    }
}

#import "Basic"()(MEMORY_DEBUGGER=true);
#import "File";
#import "File_Utilities";
#import "Window_Creation";
#import "Input";
#import "Math";
#import "String";
#import "Thread";
#import "System";
#import "Srgb";
#import "Atomics";
#import "Hash_Table";
#import "Hash";
#import "Command_Line";
#import "stb_image";
#import "Random";

Simp :: #import "Simp";

#import "Arena";
#import "Raddbg"()(ENABLED=ENABLE_RAD_DEBUGGER);
