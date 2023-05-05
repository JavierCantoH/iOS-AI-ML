import coremltools
from keras.models import load_model

output_labels = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']

file_path = 'digit-recognizer.h5'

def convert_model(model):
	print('converting...')
	coreml_model = coremltools.converters.keras.convert(model,input_names=['image'], output_names=['output'], 
                                                   class_labels=output_labels, image_input_names='image')
	coreml_model.save('/MNIST.mlmodel')
	print('model converted')

import os.path
if os.path.isfile(file_path): 
	model = load_model(file_path)
	convert_model(model)
else:
	print('no model found')
