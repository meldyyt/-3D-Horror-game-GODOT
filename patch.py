import sys

file_path = r'C:\Horror game\scenes\levels\test_level.tscn'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

void_box_resources = """
[sub_resource type="StandardMaterial3D" id="Mat_Void"]
shading_mode = 0
albedo_color = Color(0, 0, 0, 1)

[sub_resource type="BoxMesh" id="Mesh_Void"]
material = SubResource("Mat_Void")
size = Vector3(4, 4, 4)

[sub_resource type="BoxShape3D" id="Shape_VoidFloor"]
size = Vector3(4, 0.2, 4)
"""

void_node = """
[node name="ApartmentVoid" type="StaticBody3D" parent="Geometry"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, -11.5)

[node name="MeshInstance3D" type="MeshInstance3D" parent="Geometry/ApartmentVoid"]
mesh = SubResource("Mesh_Void")

[node name="VoidFloor" type="StaticBody3D" parent="Geometry/ApartmentVoid"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -1.6, 0)

[node name="CollisionShape3D" type="CollisionShape3D" parent="Geometry/ApartmentVoid/VoidFloor"]
shape = SubResource("Shape_VoidFloor")
"""

if 'Mat_Void' not in content:
    content = content.replace('[node name="TestLevel"', void_box_resources + '\n[node name="TestLevel"')
    content = content.replace('[node name="Doors"', void_node + '\n[node name="Doors"')
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Added ApartmentVoid')
else:
    print('ApartmentVoid already exists')
