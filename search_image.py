import torch
import open_clip
import os
from PIL import Image
import time     

start_time = time.time()

thisdir = os.path.dirname(os.path.realpath(__file__))
image_dir = thisdir+"/images448/"
# text_tokens = ["mountain", "marmot", "bridges", "orange lily", "shallow depth of field", "bokeh", "mountain landscape on a cloudy day", "path covered in snow under a clear evening sky"]
# text_tokens = ["photo of mountain", "photo of marmot", "photo of bridges", "photo of orange lily", "photo of shallow depth of field", "photo of bokeh", "photo of mountain landscape on a cloudy day", "photo of path covered in snow under a clear evening sky"]

text_token = os.sys.argv[1]
num_topk = int(os.sys.argv[2])

model, _, preprocess = open_clip.create_model_and_transforms('ViT-B-32', pretrained='laion2b_s34b_b79k')
tokenizer = open_clip.get_tokenizer('ViT-B-32')

model_load_time = time.time()

image_paths = os.listdir(image_dir)
listdir_time = time.time()
text = tokenizer(text_token)

tokenize_text_time = time.time()

with torch.no_grad():
    image_features = torch.load(thisdir+'/image_features_open_ViT-B-32.pt').cpu()
    text_features = model.encode_text(text).cpu()
    
    features_load_time = time.time()

    image_features_norm = image_features / image_features.norm(dim=-1, keepdim=True)
    text_features_norm = text_features / text_features.norm(dim=-1, keepdim=True)

    # Compute the similarity
    similarity = (image_features_norm @ text_features_norm.t())
    topk_values, topk_indices = similarity.topk(num_topk, dim=0)

    similarity_time = time.time()
    # print(similarity)


for j in range(num_topk):
    # print(i, j, topk_indices[i][j])
    # print(f"Image {j+1}: {image_paths[topk_indices[j]]} with score {topk_values[j][0]}")
    print(image_paths[topk_indices[j]].split('.')[0])

# print(topk_indices)
# torch.save(image_features, 'image_features.pt')
# print(f"Text token: {text_token}")
# # print("Label probs:", probs)  # prints: [[0.9927937  0.00421068 0.00299572]]
# print(f"Model load time: {model_load_time-start_time }")
# print(f"Listdir time: {listdir_time-model_load_time}")
# print(f"Tokenize text time: {tokenize_text_time-listdir_time}")
# print(f"Features load time: {features_load_time-tokenize_text_time}")
# print(f"Similarity time: {similarity_time-features_load_time}")
