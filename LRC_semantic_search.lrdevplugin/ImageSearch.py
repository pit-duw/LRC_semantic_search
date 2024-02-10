import torch
import os

# Get the path to the directory containing this script
thisdir = os.path.dirname(os.path.realpath(__file__))

# Get the UUID of the image to search and the number of top results to return from the command line arguments
search_image_UUID = os.sys.argv[1]
num_topk = int(os.sys.argv[2])+1

# Read the image UUIDs and their ID numbers in the tensor from a file
image_UUIDs = []
with open(thisdir+'/image_UUIDs.dat', 'r') as f:
    for line in f.readlines():
        image_UUIDs.append(line.split(' ')[1].strip())

with torch.no_grad():
    # Load the image features
    image_features = torch.load(thisdir+'/image_features_open_ViT-B-32.pt').cpu()
    # Get the features for the image to search
    search_image_features = image_features[image_UUIDs.index(search_image_UUID)]

    # Normalize the features
    image_features_norm = image_features / image_features.norm(dim=-1, keepdim=True)
    search_image_features_norm = search_image_features / search_image_features.norm(dim=-1, keepdim=True)

    # Compute the similarity and take the top k results
    similarity = (image_features_norm @ search_image_features_norm.t())
    topk_values, topk_indices = similarity.topk(num_topk, dim=0)
        
# Print the UUID of the top k results, while skipping the first, which is just the searched image itself
for j in range(1,num_topk):
    print(image_UUIDs[topk_indices[j]])
