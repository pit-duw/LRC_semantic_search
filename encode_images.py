import torch
import open_clip
import os
from PIL import Image
# from tqdm import tqdm

thisdir = os.path.dirname(os.path.realpath(__file__))
image_dir = thisdir+"/images448/"

model, _, preprocess = open_clip.create_model_and_transforms('ViT-B-32', pretrained='laion2b_s34b_b79k')
tokenizer = open_clip.get_tokenizer('ViT-B-32')

image_paths = os.listdir(image_dir) # [:4]+["IMG_1163.JPG", "IMG_1645.JPG", "IMG_1802.JPG", "IMG_2482.JPG"]

images = []
for path in image_paths:
    # print("Preprocessing image:", path)
    image = preprocess(Image.open(image_dir+path)).unsqueeze(0)
    images.append(image)

image_batch = torch.cat(images)
# pbar = tqdm(total=len(image_batch), desc="Encoding images")

# def update_pbar(*args):
#     pbar.update()

# with torch.autograd.profiler.profile(record_shapes=True, profile_memory=True) as prof:
#     update_pbar()

# After computing the features
with torch.no_grad():
    image_features = model.encode_image(image_batch)

# pbar.close()

# Save the features
torch.save(image_features, thisdir+'/image_features_open_ViT-B-32.pt')

print("Successfully built search index!")