import torch
import open_clip
import os

thisdir = os.path.dirname(os.path.realpath(__file__))
image_dir = thisdir+"/images320/"

search_image_UUID = os.sys.argv[1]
num_topk = int(os.sys.argv[2])+1


# Read the image UUIDs and their ID numbers in the tensor from a file
image_UUIDs = []
with open(thisdir+'/image_UUIDs.dat', 'r') as f:
    for line in f.readlines():
        image_UUIDs.append(line.split(' ')[1].strip())

with torch.no_grad():
    image_features = torch.load(thisdir+'/image_features_open_ViT-B-32.pt').cpu()
    search_image_features = image_features[image_UUIDs.index(search_image_UUID)]

    image_features_norm = image_features / image_features.norm(dim=-1, keepdim=True)
    search_image_features_norm = search_image_features / search_image_features.norm(dim=-1, keepdim=True)

    # Compute the similarity
    similarity = (image_features_norm @ search_image_features_norm.t())
    topk_values, topk_indices = similarity.topk(num_topk, dim=0)
        

for j in range(1,num_topk):
    print(image_UUIDs[topk_indices[j]])
