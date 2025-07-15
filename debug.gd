@tool
extends TextureRect

func _ready():
	# Define the size of the noise map
	var width = 50
	var height = 50

	# 1. Create and configure the noise generator
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX	
	noise.seed = 1
	noise.frequency = 0.05

	# 2. Create an image to draw on
	var image = Image.create(width, height, false, Image.FORMAT_L8) # L8 is 8-bit grayscale

	# 3. Loop through each pixel and set its color based on noise
	for y in range(height):
		for x in range(width):
			# Get the noise value for the (x, y) coordinate. It's between -1.0 and 1.0.
			var noise_value = noise.get_noise_2d(x, y)
			
			# Map the noise value from [-1, 1] to a grayscale color [0, 1]
			var color_value = (noise_value + 1.0) / 2.0
			
			# Set the pixel color on the image
			image.set_pixel(x, y, Color(color_value, color_value, color_value))

	# 4. Create a texture from the image and display it
	var image_texture = ImageTexture.create_from_image(image)
	self.texture = image_texture
