#!/bin/bash

pip3 install --user pillow

image_path='C:/Users/KUSH P MAKWANA/Syllabus Tracker/image/Sanika.jpeg'
filename=$(basename "$image_path")
filename=$(echo "$filename" | cut -d'.' -f1)

if [ -z "$1" ]; then
    echo "Input image path is not provided. Using default test image: $image_path"
else
    echo "Input image path: $1"
    image_path="$1"
fi

output_image_path="${image_path%.*}_output.jpg"

echo "Generating input file for image"

# Python script to process image
python3 - <<END
import subprocess
import sys
import os
from PIL import Image

def install_pillow():
    try:
        from PIL import Image
        print("Pillow is already installed.")
    except ModuleNotFoundError:
        print("Pillow not found. Installing...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "--user", "Pillow"])
        try:
            from PIL import Image
            print("Pillow installed successfully.")
        except ModuleNotFoundError:
            print("Installation failed. Try running the script as administrator.")

install_pillow()

os.makedirs("./temp/", exist_ok=True)

image_path = r"$image_path"  # Ensure the path is passed correctly
try:
    img = Image.open(image_path)
except FileNotFoundError:
    print(f"Error: File {image_path} not found.")
    sys.exit(1)

img = img.convert('L')  # Convert to grayscale
img = img.resize((256, 256), Image.BICUBIC)

width, height = img.size

def to_hex(val):
    return format(val, '02X')

with open('./temp/generated_input.txt', 'w') as file:
    for y in range(height):
        for x in range(width):
            pixel_value = img.getpixel((x, y))
            file.write(to_hex(pixel_value) + '\t')
END

echo "Launching Vivado Simulation"

# Run Vivado properly
"C:/XilinxVivado/Vivado/2024.2/bin/vivado.bat" -mode tcl << EOF
open_project "C:/Users/KUSH P MAKWANA/canny/canny.xpr"
launch_simulation
EOF

echo "Generating output image"

# Python script to generate output image
python3 - <<END
import os
from PIL import Image

input_file = './temp/edgefile_canny.txt'
output_image_path = r"$output_image_path"  # Fixing variable scope issue

if not os.path.exists(input_file) or os.stat(input_file).st_size == 0:
    print("Error: edgefile_canny.txt is missing or empty.")
    exit(1)

with open(input_file, 'r') as file:
    content = file.read()

numbers = [int(val.strip(), 16) for val in content.split() if val.strip()]
if len(numbers) < 256 * 256:
    print(f"Error: Expected 256x256 values, got {len(numbers)}")
    exit(1)

image = Image.new('L', (256, 256))

for y in range(256):
    for x in range(256):
        pixel_value = numbers[y * 256 + x]
        image.putpixel((x, y), pixel_value)

image.save(output_image_path)
print(f"Output Image saved as: {output_image_path}")
END
