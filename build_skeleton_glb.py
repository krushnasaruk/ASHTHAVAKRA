import math
import struct
import json
import base64
import os

SCALE = 0.001

# Anatomical dimensions from standard human hand anthropometry
BONE_DATA = {
    # Thumb
    'metacarpal_thumb': {'len': 46.2, 'w_base': 14.5, 'w_shaft': 9.2, 'w_head': 13.8, 'finger': 'thumb', 'name': 'metacarpal 1 (thumb)', 'joints': ['CMC', 'MCP']},
    'proximal_phalanx_thumb': {'len': 31.6, 'w_base': 13.2, 'w_shaft': 8.5, 'w_head': 11.4, 'finger': 'thumb', 'name': 'proximal phalanx, thumb', 'joints': ['MCP', 'IP']},
    'distal_phalanx_thumb': {'len': 21.7, 'w_base': 11.8, 'w_shaft': 7.2, 'w_head': 9.8, 'finger': 'thumb', 'name': 'distal phalanx, thumb', 'joints': ['IP'], 'is_distal': True},

    # Index
    'metacarpal_index': {'len': 68.1, 'w_base': 14.2, 'w_shaft': 8.8, 'w_head': 13.5, 'finger': 'index', 'name': 'metacarpal 2 (index)', 'joints': ['CMC', 'MCP']},
    'proximal_phalanx_index': {'len': 39.8, 'w_base': 13.1, 'w_shaft': 7.8, 'w_head': 11.2, 'finger': 'index', 'name': 'proximal phalanx, index finger', 'joints': ['MCP', 'PIP']},
    'middle_phalanx_index': {'len': 22.4, 'w_base': 11.5, 'w_shaft': 6.8, 'w_head': 9.6, 'finger': 'index', 'name': 'middle phalanx, index finger', 'joints': ['PIP', 'DIP']},
    'distal_phalanx_index': {'len': 15.8, 'w_base': 9.4, 'w_shaft': 5.5, 'w_head': 7.8, 'finger': 'index', 'name': 'distal phalanx, index finger', 'joints': ['DIP'], 'is_distal': True},

    # Middle
    'metacarpal_middle': {'len': 64.6, 'w_base': 14.0, 'w_shaft': 8.9, 'w_head': 13.8, 'finger': 'middle', 'name': 'metacarpal 3 (middle)', 'joints': ['CMC', 'MCP']},
    'proximal_phalanx_middle': {'len': 44.6, 'w_base': 13.8, 'w_shaft': 8.4, 'w_head': 11.8, 'finger': 'middle', 'name': 'proximal phalanx, middle finger', 'joints': ['MCP', 'PIP']},
    'middle_phalanx_middle': {'len': 26.3, 'w_base': 12.0, 'w_shaft': 7.2, 'w_head': 10.1, 'finger': 'middle', 'name': 'middle phalanx, middle finger', 'joints': ['PIP', 'DIP']},
    'distal_phalanx_middle': {'len': 17.4, 'w_base': 9.8, 'w_shaft': 5.8, 'w_head': 8.2, 'finger': 'middle', 'name': 'distal phalanx, middle finger', 'joints': ['DIP'], 'is_distal': True},

    # Ring
    'metacarpal_ring': {'len': 58.0, 'w_base': 12.5, 'w_shaft': 7.8, 'w_head': 12.2, 'finger': 'ring', 'name': 'metacarpal 4 (ring)', 'joints': ['CMC', 'MCP']},
    'proximal_phalanx_ring': {'len': 41.3, 'w_base': 12.8, 'w_shaft': 7.6, 'w_head': 10.9, 'finger': 'ring', 'name': 'proximal phalanx, ring finger', 'joints': ['MCP', 'PIP']},
    'middle_phalanx_ring': {'len': 25.7, 'w_base': 11.2, 'w_shaft': 6.5, 'w_head': 9.4, 'finger': 'ring', 'name': 'middle phalanx, ring finger', 'joints': ['PIP', 'DIP']},
    'distal_phalanx_ring': {'len': 17.3, 'w_base': 9.2, 'w_shaft': 5.4, 'w_head': 7.9, 'finger': 'ring', 'name': 'distal phalanx, ring finger', 'joints': ['DIP'], 'is_distal': True},

    # Pinky
    'metacarpal_pinky': {'len': 53.7, 'w_base': 12.0, 'w_shaft': 7.2, 'w_head': 11.5, 'finger': 'pinky', 'name': 'metacarpal 5 (pinky)', 'joints': ['CMC', 'MCP']},
    'proximal_phalanx_pinky': {'len': 32.7, 'w_base': 11.5, 'w_shaft': 6.6, 'w_head': 9.8, 'finger': 'pinky', 'name': 'proximal phalanx, pinky finger', 'joints': ['MCP', 'PIP']},
    'middle_phalanx_pinky': {'len': 18.1, 'w_base': 10.1, 'w_shaft': 5.8, 'w_head': 8.4, 'finger': 'pinky', 'name': 'middle phalanx, pinky finger', 'joints': ['PIP', 'DIP']},
    'distal_phalanx_pinky': {'len': 15.9, 'w_base': 8.6, 'w_shaft': 4.8, 'w_head': 7.2, 'finger': 'pinky', 'name': 'distal phalanx, pinky finger', 'joints': ['DIP'], 'is_distal': True},
}

CARPALS = {
    'scaphoid': {'pos': (-14.0, -14.0, 0.0), 'size': (14.0, 10.0, 10.0), 'name': 'scaphoid', 'joints': ['radiocarpal', 'midcarpal']},
    'lunate': {'pos': (-4.0, -13.5, 0.0), 'size': (12.0, 11.0, 9.5), 'name': 'lunate', 'joints': ['radiocarpal', 'midcarpal']},
    'triquetrum': {'pos': (6.0, -14.5, 0.0), 'size': (11.0, 10.0, 9.0), 'name': 'triquetrum', 'joints': ['midcarpal', 'pisotriquetral']},
    'pisiform': {'pos': (7.5, -13.0, 5.0), 'size': (8.0, 8.5, 7.5), 'name': 'pisiform', 'joints': ['pisotriquetral']},
    'trapezium': {'pos': (-16.0, -4.0, 1.0), 'size': (13.0, 11.0, 11.0), 'name': 'trapezium', 'joints': ['CMC', 'scaphotrapezial']},
    'trapezoid': {'pos': (-7.5, -4.5, 0.0), 'size': (10.0, 10.0, 9.5), 'name': 'trapezoid', 'joints': ['CMC', 'scaphotrapezoid']},
    'capitate': {'pos': (0.5, -3.5, 0.0), 'size': (15.0, 14.0, 12.0), 'name': 'capitate', 'joints': ['CMC', 'midcarpal']},
    'hamate': {'pos': (9.5, -4.0, 0.5), 'size': (13.0, 13.0, 11.5), 'name': 'hamate', 'joints': ['CMC']},
}

def generate_long_bone(b_info):
    length = b_info['len'] * SCALE
    w_base = (b_info['w_base'] * 0.5) * SCALE
    w_shaft = (b_info['w_shaft'] * 0.5) * SCALE
    w_head = (b_info['w_head'] * 0.5) * SCALE
    is_distal = b_info.get('is_distal', False)

    num_rings = 16
    num_segs = 16

    vertices = []
    normals = []
    shaft_indices = []
    ends_indices = []

    for r in range(num_rings + 1):
        v_frac = r / float(num_rings)
        y = v_frac * length

        if v_frac < 0.22:
            t = v_frac / 0.22
            rx = w_base * (1.0 - t * 0.45)
            rz = w_base * 0.85 * (1.0 - t * 0.35)
            z_offset = -0.15 * (1.0 - t) * length * 0.1
        elif v_frac < 0.78:
            t = (v_frac - 0.22) / 0.56
            waist = math.sin(t * math.pi)
            rx = w_shaft * (1.0 - waist * 0.12)
            rz = w_shaft * 0.85
            z_offset = -math.sin(t * math.pi) * length * 0.035
        else:
            t = (v_frac - 0.78) / 0.22
            rx = w_shaft + t * (w_head - w_shaft)
            rz = w_shaft * 0.85 + t * (w_head * 0.85 - w_shaft * 0.85)
            z_offset = 0.0
            if is_distal and v_frac > 0.88:
                rx *= 1.15
                rz *= 0.65

        for s in range(num_segs):
            theta = (s / float(num_segs)) * 2.0 * math.pi
            rad_mult = 1.0
            if v_frac > 0.82 and not is_distal:
                rad_mult = 1.0 - 0.14 * abs(math.cos(theta * 2.0))

            x = math.cos(theta) * rx * rad_mult
            z = math.sin(theta) * rz * rad_mult + z_offset

            nx = math.cos(theta)
            ny = 0.0
            nz = math.sin(theta)
            nl = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0

            vertices.append((x, y, z))
            normals.append((nx / nl, ny / nl, nz / nl))

    base_center = len(vertices)
    vertices.append((0.0, 0.0, -0.001 * length))
    normals.append((0.0, -1.0, 0.0))

    head_center = len(vertices)
    vertices.append((0.0, length, 0.0))
    normals.append((0.0, 1.0, 0.0))

    for r in range(num_rings):
        is_shaft = (3 <= r < 12)
        target = shaft_indices if is_shaft else ends_indices
        for s in range(num_segs):
            s_next = (s + 1) % num_segs
            i0 = r * num_segs + s
            i1 = r * num_segs + s_next
            i2 = (r + 1) * num_segs + s_next
            i3 = (r + 1) * num_segs + s
            target.extend([i0, i1, i2, i0, i2, i3])

    for s in range(num_segs):
        s_next = (s + 1) % num_segs
        ends_indices.extend([base_center, s_next, s])

    top_offset = num_rings * num_segs
    for s in range(num_segs):
        s_next = (s + 1) % num_segs
        ends_indices.extend([head_center, top_offset + s, top_offset + s_next])

    return vertices, normals, shaft_indices, ends_indices

def generate_carpal(size_tuple):
    sx, sy, sz = [s * 0.5 * SCALE for s in size_tuple]
    raw_verts = [
        (-sx * 0.9, -sy * 0.8, -sz * 0.8), (sx * 0.9, -sy * 0.8, -sz * 0.8),
        (sx * 0.9, sy * 0.8, -sz * 0.8), (-sx * 0.9, sy * 0.8, -sz * 0.8),
        (-sx * 0.8, -sy * 0.9, sz * 0.9), (sx * 0.8, -sy * 0.9, sz * 0.9),
        (sx * 0.8, sy * 0.9, sz * 0.9), (-sx * 0.8, sy * 0.9, sz * 0.9),
        (-sx * 1.1, 0.0, 0.0), (sx * 1.1, 0.0, 0.0),
        (0.0, -sy * 1.1, 0.0), (0.0, sy * 1.1, 0.0),
        (0.0, 0.0, -sz * 1.1), (0.0, 0.0, sz * 1.1)
    ]
    vertices = []
    normals = []
    for x, y, z in raw_verts:
        vertices.append((x, y, z))
        nl = math.sqrt(x*x + y*y + z*z) or 1.0
        normals.append((x/nl, y/nl, z/nl))

    indices = [
        0, 1, 10,  1, 5, 10,  5, 4, 10,  4, 0, 10,
        3, 2, 11,  2, 6, 11,  6, 7, 11,  7, 3, 11,
        0, 3, 8,   3, 7, 8,   7, 4, 8,   4, 0, 8,
        1, 2, 9,   2, 6, 9,   6, 5, 9,   5, 1, 9,
        0, 1, 12,  1, 2, 12,  2, 3, 12,  3, 0, 12,
        4, 5, 13,  5, 6, 13,  6, 7, 13,  7, 4, 13
    ]
    return vertices, normals, indices

def generate_finger_skin_capsule(radius_base, radius_tip, length, has_dome=False):
    """Generates a smooth tapered flesh capsule for a finger phalanx segment."""
    rings = 10
    segs = 14
    verts = []
    norms = []
    inds = []

    for r in range(rings + 1):
        v = r / float(rings)
        y = v * length
        # Taper
        rad = radius_base + v * (radius_tip - radius_base)
        for s in range(segs):
            theta = (s / float(segs)) * 2.0 * math.pi
            x = math.cos(theta) * rad
            z = math.sin(theta) * (rad * 0.90) # Slightly elliptical cross section
            verts.append((x, y, z))
            nx = math.cos(theta)
            nz = math.sin(theta)
            norms.append((nx, 0.0, nz))

    for r in range(rings):
        for s in range(segs):
            s_next = (s + 1) % segs
            i0 = r * segs + s
            i1 = r * segs + s_next
            i2 = (r + 1) * segs + s_next
            i3 = (r + 1) * segs + s
            inds.extend([i0, i1, i2, i0, i2, i3])

    if has_dome:
        # Rounded dome fingertip
        dome_rings = 6
        tip_start_idx = len(verts)
        dome_rad = radius_tip
        y_top = length

        for dr in range(1, dome_rings + 1):
            phi = (dr / float(dome_rings)) * (math.pi * 0.5)
            y = y_top + math.sin(phi) * dome_rad * 0.8
            r_slice = math.cos(phi) * dome_rad
            for s in range(segs):
                theta = (s / float(segs)) * 2.0 * math.pi
                x = math.cos(theta) * r_slice
                z = math.sin(theta) * (r_slice * 0.90)
                verts.append((x, y, z))
                nx = math.cos(theta) * math.cos(phi)
                ny = math.sin(phi)
                nz = math.sin(theta) * math.cos(phi)
                nl = math.sqrt(nx*nx + ny*ny + nz*nz) or 1.0
                norms.append((nx/nl, ny/nl, nz/nl))

        # Stitch top ring of cylinder to first ring of dome
        top_cyl_ring = rings * segs
        for s in range(segs):
            s_next = (s + 1) % segs
            i0 = top_cyl_ring + s
            i1 = top_cyl_ring + s_next
            i2 = tip_start_idx + s_next
            i3 = tip_start_idx + s
            inds.extend([i0, i1, i2, i0, i2, i3])

        # Stitch dome rings
        for dr in range(dome_rings - 1):
            for s in range(segs):
                s_next = (s + 1) % segs
                i0 = tip_start_idx + dr * segs + s
                i1 = tip_start_idx + dr * segs + s_next
                i2 = tip_start_idx + (dr + 1) * segs + s_next
                i3 = tip_start_idx + (dr + 1) * segs + s
                inds.extend([i0, i1, i2, i0, i2, i3])

        # Dome apex
        apex_idx = len(verts)
        verts.append((0.0, y_top + dome_rad * 0.8, 0.0))
        norms.append((0.0, 1.0, 0.0))
        last_dome_ring = tip_start_idx + (dome_rings - 1) * segs
        for s in range(segs):
            s_next = (s + 1) % segs
            inds.extend([apex_idx, last_dome_ring + s, last_dome_ring + s_next])

    return verts, norms, inds

def generate_palm_skin_envelope():
    """Generates the translucent fleshy palm hull covering carpals and metacarpals."""
    rings = 16
    segs = 20
    verts = []
    norms = []
    inds = []

    # Envelope from wrist (y = -0.020) to knuckles (y = 0.065)
    for r in range(rings + 1):
        v = r / float(rings)
        y = -0.022 + v * 0.088
        
        # Palm width rx: starts ~24mm at wrist, expands to ~37mm at knuckles
        rx = 0.023 + v * 0.015 - (0.005 * math.sin(v * math.pi))
        # Palm thickness rz: ~11mm at wrist, ~10mm at center, ~9mm at knuckles
        rz = 0.010 - (0.002 * (v - 0.5)**2)
        # Lateral offset (thumb side is wider)
        cx = -0.002 * (1.0 - v)
        cz = 0.001

        for s in range(segs):
            theta = (s / float(segs)) * 2.0 * math.pi
            x = cx + math.cos(theta) * rx
            z = cz + math.sin(theta) * rz
            verts.append((x, y, z))
            nx = math.cos(theta)
            nz = math.sin(theta)
            nl = math.sqrt(nx*nx + nz*nz) or 1.0
            norms.append((nx/nl, 0.0, nz/nl))

    for r in range(rings):
        for s in range(segs):
            s_next = (s + 1) % segs
            i0 = r * segs + s
            i1 = r * segs + s_next
            i2 = (r + 1) * segs + s_next
            i3 = (r + 1) * segs + s
            inds.extend([i0, i1, i2, i0, i2, i3])

    # Cap at wrist bottom
    bot_center = len(verts)
    verts.append((0.0, -0.022, 0.0))
    norms.append((0.0, -1.0, 0.0))
    for s in range(segs):
        s_next = (s + 1) % segs
        inds.extend([bot_center, s_next, s])

    return verts, norms, inds

# GLTF Builder Structures
bin_buffer = bytearray()
buffer_views = []
accessors = []
meshes = []
nodes = []

def add_buffer_data(data, target=None):
    offset = len(bin_buffer)
    pad = (4 - (offset % 4)) % 4
    if pad > 0:
        bin_buffer.extend(b'\x00' * pad)
        offset += pad
    bin_buffer.extend(data)
    length = len(data)
    bv_idx = len(buffer_views)
    bv = {"buffer": 0, "byteOffset": offset, "byteLength": length}
    if target:
        bv["target"] = target
    buffer_views.append(bv)
    return bv_idx

def add_accessor(bv_idx, comp_type, count, acc_type, min_val=None, max_val=None):
    acc_idx = len(accessors)
    acc = {
        "bufferView": bv_idx,
        "byteOffset": 0,
        "componentType": comp_type,
        "count": count,
        "type": acc_type
    }
    if min_val is not None:
        acc["min"] = min_val
    if max_val is not None:
        acc["max"] = max_val
    accessors.append(acc)
    return acc_idx

def store_mesh_data(verts, norms, shaft_inds, ends_inds=None, skin_inds=None, is_phalanx=False):
    pos_bytes = bytearray()
    min_p = [float('inf'), float('inf'), float('inf')]
    max_p = [float('-inf'), float('-inf'), float('-inf')]
    for v in verts:
        pos_bytes.extend(struct.pack('<fff', v[0], v[1], v[2]))
        for i in range(3):
            if v[i] < min_p[i]: min_p[i] = v[i]
            if v[i] > max_p[i]: max_p[i] = v[i]
    pos_bv = add_buffer_data(pos_bytes, 34962)
    pos_acc = add_accessor(pos_bv, 5126, len(verts), "VEC3", min_p, max_p)

    norm_bytes = bytearray()
    for n in norms:
        norm_bytes.extend(struct.pack('<fff', n[0], n[1], n[2]))
    norm_bv = add_buffer_data(norm_bytes, 34962)
    norm_acc = add_accessor(norm_bv, 5126, len(norms), "VEC3")

    primitives = []
    
    # Primitive 0: Shaft (material 0 for yellow phalanx shaft, material 3 for grey metacarpal)
    if shaft_inds:
        idx_bytes = bytearray()
        for idx in shaft_inds:
            idx_bytes.extend(struct.pack('<H', idx))
        idx_bv = add_buffer_data(idx_bytes, 34963)
        idx_acc = add_accessor(idx_bv, 5123, len(shaft_inds), "SCALAR", [min(shaft_inds)], [max(shaft_inds)])
        primitives.append({
            "attributes": {"POSITION": pos_acc, "NORMAL": norm_acc},
            "indices": idx_acc,
            "material": 0 if is_phalanx else 3
        })

    # Primitive 1: Joint Ends / Epiphysis (material 1: pale grey)
    if ends_inds:
        idx_bytes = bytearray()
        for idx in ends_inds:
            idx_bytes.extend(struct.pack('<H', idx))
        idx_bv = add_buffer_data(idx_bytes, 34963)
        idx_acc = add_accessor(idx_bv, 5123, len(ends_inds), "SCALAR", [min(ends_inds)], [max(ends_inds)])
        primitives.append({
            "attributes": {"POSITION": pos_acc, "NORMAL": norm_acc},
            "indices": idx_acc,
            "material": 1
        })

    # Primitive 2: Skin (material 2: translucent faint grey)
    if skin_inds:
        idx_bytes = bytearray()
        for idx in skin_inds:
            idx_bytes.extend(struct.pack('<H', idx))
        idx_bv = add_buffer_data(idx_bytes, 34963)
        idx_acc = add_accessor(idx_bv, 5123, len(skin_inds), "SCALAR", [min(skin_inds)], [max(skin_inds)])
        primitives.append({
            "attributes": {"POSITION": pos_acc, "NORMAL": norm_acc},
            "indices": idx_acc,
            "material": 2
        })

    mesh_idx = len(meshes)
    meshes.append({"primitives": primitives})
    return mesh_idx

# 1. Process 8 Carpal Bones (Material 1: Pale grey epiphysis)
carpal_node_indices = []
for c_key, c_info in CARPALS.items():
    verts, norms, inds = generate_carpal(c_info['size'])
    mesh_idx = store_mesh_data(verts, norms, [], ends_inds=inds)
    px, py, pz = [p * SCALE for p in c_info['pos']]
    node_idx = len(nodes)
    nodes.append({
        "name": c_key,
        "mesh": mesh_idx,
        "translation": [px, py, pz],
        "extras": {
            "name": c_info['name'],
            "finger": "wrist",
            "boneType": "carpal",
            "joints": c_info['joints']
        }
    })
    carpal_node_indices.append(node_idx)

# 2. Process Long Bones & Hierarchical Chains
finger_root_nodes = []

finger_specs = [
    {
        'finger': 'thumb',
        'bones': ['metacarpal_thumb', 'proximal_phalanx_thumb', 'distal_phalanx_thumb'],
        'base_pos': (-0.016, -0.003, 0.002),
        'base_rot': (0.0, 0.0, 0.38, 0.925),
        'skin_radii': [(0.010, 0.009), (0.009, 0.008), (0.008, 0.0065)]
    },
    {
        'finger': 'index',
        'bones': ['metacarpal_index', 'proximal_phalanx_index', 'middle_phalanx_index', 'distal_phalanx_index'],
        'base_pos': (-0.009, 0.000, 0.0),
        'base_rot': (0.0, 0.0, 0.045, 0.999),
        'skin_radii': [(0.009, 0.008), (0.008, 0.007), (0.007, 0.006), (0.006, 0.005)]
    },
    {
        'finger': 'middle',
        'bones': ['metacarpal_middle', 'proximal_phalanx_middle', 'middle_phalanx_middle', 'distal_phalanx_middle'],
        'base_pos': (0.001, 0.002, 0.0),
        'base_rot': (0.0, 0.0, 0.0, 1.0),
        'skin_radii': [(0.0095, 0.0085), (0.0085, 0.0075), (0.0075, 0.0065), (0.0065, 0.0055)]
    },
    {
        'finger': 'ring',
        'bones': ['metacarpal_ring', 'proximal_phalanx_ring', 'middle_phalanx_ring', 'distal_phalanx_ring'],
        'base_pos': (0.010, -0.001, 0.0),
        'base_rot': (0.0, 0.0, -0.035, 0.999),
        'skin_radii': [(0.0085, 0.0078), (0.0078, 0.0068), (0.0068, 0.0058), (0.0058, 0.0048)]
    },
    {
        'finger': 'pinky',
        'bones': ['metacarpal_pinky', 'proximal_phalanx_pinky', 'middle_phalanx_pinky', 'distal_phalanx_pinky'],
        'base_pos': (0.018, -0.004, 0.0),
        'base_rot': (0.0, 0.0, -0.08, 0.997),
        'skin_radii': [(0.0078, 0.0070), (0.0070, 0.0060), (0.0060, 0.0050), (0.0050, 0.0042)]
    }
]

for f_spec in finger_specs:
    chain_nodes = []
    for b_idx, b_key in enumerate(f_spec['bones']):
        b_info = BONE_DATA[b_key]
        is_phalanx = (b_idx > 0)
        verts, norms, shaft_inds, ends_inds = generate_long_bone(b_info)
        
        # Bone mesh with Yellow Shaft (phalanx) or Grey Shaft (metacarpal) + Pale Joint Ends
        mesh_idx = store_mesh_data(verts, norms, shaft_inds, ends_inds=ends_inds, is_phalanx=is_phalanx)
        
        n_idx = len(nodes)
        node_def = {
            "name": b_key,
            "mesh": mesh_idx,
            "extras": {
                "name": b_info['name'],
                "finger": b_info['finger'],
                "boneType": "phalanx" if is_phalanx else "metacarpal",
                "lengthMm": b_info['len'],
                "joints": b_info['joints']
            }
        }
        
        if b_idx == 0:
            node_def["translation"] = list(f_spec['base_pos'])
            node_def["rotation"] = list(f_spec['base_rot'])
        else:
            prev_b_key = f_spec['bones'][b_idx - 1]
            prev_len = BONE_DATA[prev_b_key]['len'] * SCALE
            node_def["translation"] = [0.0, prev_len, 0.0]

        # Generate accompanying finger skin segment attached to this phalanx node
        if is_phalanx:
            r_base, r_tip = f_spec['skin_radii'][b_idx]
            is_distal_bone = b_info.get('is_distal', False)
            skin_v, skin_n, skin_i = generate_finger_skin_capsule(r_base, r_tip, b_info['len'] * SCALE, has_dome=is_distal_bone)
            skin_mesh_idx = store_mesh_data(skin_v, skin_n, [], skin_inds=skin_i)
            skin_node_idx = len(nodes) + 1 # Child node
            skin_node_def = {
                "name": f"skin_{b_key}",
                "mesh": skin_mesh_idx,
                "translation": [0.0, 0.0, 0.0],
                "extras": {"type": "skin", "finger": b_info['finger']}
            }
            # Link skin node as a sibling/child
            node_def["children"] = [skin_node_idx]
            nodes.append(node_def)
            nodes.append(skin_node_def)
            chain_nodes.append(n_idx)
        else:
            nodes.append(node_def)
            chain_nodes.append(n_idx)

    # Link hierarchical bone chain (parent phalanx -> child phalanx)
    for i in range(len(chain_nodes) - 1):
        parent_idx = chain_nodes[i]
        child_idx = chain_nodes[i + 1]
        if "children" in nodes[parent_idx]:
            nodes[parent_idx]["children"].append(child_idx)
        else:
            nodes[parent_idx]["children"] = [child_idx]
        
    finger_root_nodes.append(chain_nodes[0])

# 3. Translucent Palm & Wrist Skin Envelope
palm_verts, palm_norms, palm_inds = generate_palm_skin_envelope()
palm_mesh_idx = store_mesh_data(palm_verts, palm_norms, [], skin_inds=palm_inds)
palm_node_idx = len(nodes)
nodes.append({
    "name": "skin_palm_envelope",
    "mesh": palm_mesh_idx,
    "translation": [0.0, 0.0, 0.0],
    "extras": {
        "name": "Translucent Palm Envelope",
        "type": "skin"
    }
})

# Root Wrist Node
wrist_children = carpal_node_indices + finger_root_nodes + [palm_node_idx]
wrist_node_idx = len(nodes)
nodes.append({
    "name": "wrist",
    "children": wrist_children,
    "translation": [0.0, 0.0, 0.0]
})

# Materials:
# 0: Bone Shaft (Phalanx Diaphysis) - Saturated Vivid Yellow (#ffd54a) matching reference
# 1: Joint Ends (Epiphysis) - Soft neutral pale grey (#b5bec4)
# 2: Skin Envelope - Translucent grey with faint rim (#e8efef, opacity 0.14)
# 3: Metacarpal Shaft - Sleek mid-grey (#c9d0d4)
materials = [
    {
        "name": "Bone_Shaft_Highlight_Yellow",
        "pbrMetallicRoughness": {
            "baseColorFactor": [1.0, 0.835, 0.29, 1.0], # #ffd54a
            "roughnessFactor": 0.35,
            "metallicFactor": 0.05
        },
        "emissiveFactor": [0.35, 0.29, 0.10]
    },
    {
        "name": "Bone_Epiphysis_PaleGrey",
        "pbrMetallicRoughness": {
            "baseColorFactor": [0.71, 0.75, 0.77, 1.0], # #b5bec4
            "roughnessFactor": 0.55,
            "metallicFactor": 0.02
        }
    },
    {
        "name": "Skin_Translucent_Silhouette",
        "pbrMetallicRoughness": {
            "baseColorFactor": [0.91, 0.94, 0.94, 0.14], # #e8efef
            "roughnessFactor": 0.45,
            "metallicFactor": 0.0
        },
        "alphaMode": "BLEND"
    },
    {
        "name": "Bone_Metacarpal_MidGrey",
        "pbrMetallicRoughness": {
            "baseColorFactor": [0.79, 0.82, 0.84, 1.0], # #c9d0d4
            "roughnessFactor": 0.45,
            "metallicFactor": 0.05
        }
    }
]

gltf = {
    "asset": {
        "version": "2.0",
        "generator": "ASHTAVAKRA Biomechanical Hand Skeleton Generator v3.0",
        "copyright": "Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0)"
    },
    "scene": 0,
    "scenes": [{"name": "AnatomicalHandSkeleton", "nodes": [wrist_node_idx]}],
    "nodes": nodes,
    "meshes": meshes,
    "materials": materials,
    "accessors": accessors,
    "bufferViews": buffer_views,
    "buffers": [{"byteLength": len(bin_buffer)}]
}

# Encode glTF JSON chunk
json_str = json.dumps(gltf, separators=(',', ':'))
json_bytes = json_str.encode('utf-8')
json_pad = (4 - (len(json_bytes) % 4)) % 4
if json_pad > 0:
    json_bytes += b' ' * json_pad

# 4-byte align BIN
bin_pad = (4 - (len(bin_buffer) % 4)) % 4
if bin_pad > 0:
    bin_buffer.extend(b'\x00' * bin_pad)

# Build GLB File
total_glb_len = 12 + 8 + len(json_bytes) + 8 + len(bin_buffer)

glb_bytes = bytearray()
glb_bytes.extend(struct.pack('<4sII', b'glTF', 2, total_glb_len))
glb_bytes.extend(struct.pack('<I4s', len(json_bytes), b'JSON'))
glb_bytes.extend(json_bytes)
glb_bytes.extend(struct.pack('<I4s', len(bin_buffer), b'BIN\0'))
glb_bytes.extend(bin_buffer)

# Output paths
out_glb_path = os.path.join('mobile', 'assets', 'hand', 'skeleton.glb')
out_b64_path = os.path.join('mobile', 'assets', 'hand', 'skeleton_b64.js')

with open(out_glb_path, 'wb') as f:
    f.write(glb_bytes)

b64_str = base64.b64encode(glb_bytes).decode('ascii')
with open(out_b64_path, 'w', encoding='utf-8') as f:
    f.write(f'window.SKELETON_GLB_B64 = "{b64_str}";\n')

print(f"Generated {out_glb_path} ({len(glb_bytes)} bytes)")
print(f"Generated {out_b64_path} ({len(b64_str)} chars b64)")
print(f"Bones Count: 8 carpal, 5 metacarpal, 14 phalanx. Total bones: 27.")
