import torch
import open_clip
import os
from PIL import Image

thisdir = os.path.dirname(os.path.realpath(__file__))
image_dir = thisdir+"/images320/"

model, _, preprocess = open_clip.create_model_and_transforms('ViT-B-32', pretrained='laion2b_s34b_b79k')
tokenizer = open_clip.get_tokenizer('ViT-B-32')

image_paths = os.listdir(image_dir)

images = []
for path in image_paths:
    image = preprocess(Image.open(image_dir+path)).unsqueeze(0)
    images.append(image)

image_batch = torch.cat(images)

with torch.no_grad():
    image_features = model.encode_image(image_batch)

# Save the features
torch.save(image_features, thisdir+'/image_features_open_ViT-B-32.pt')
