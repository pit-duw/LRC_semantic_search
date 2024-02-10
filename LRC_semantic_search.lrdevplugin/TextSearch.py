import torch
import open_clip
import os

# Get the path to the directory containing this script
thisdir = os.path.dirname(os.path.realpath(__file__))

# Get the text to search for and the number of top results to return from the command line arguments
text = os.sys.argv[1]
num_topk = int(os.sys.argv[2])

# Load the model and tokenizer
model, _, preprocess = open_clip.create_model_and_transforms('ViT-B-32', pretrained='laion2b_s34b_b79k')
tokenizer = open_clip.get_tokenizer('ViT-B-32')

# Generate a token for the text
text_token = tokenizer(text)

with torch.no_grad():
    # Load the image features
    image_features = torch.load(thisdir+'/image_features_open_ViT-B-32.pt').cpu()
    # Encode the text
    text_features = model.encode_text(text_token).cpu()

    # Normalize the features
    image_features_norm = image_features / image_features.norm(dim=-1, keepdim=True)
    text_features_norm = text_features / text_features.norm(dim=-1, keepdim=True)

    # Compute the similarity and take the top k results
    similarity = (image_features_norm @ text_features_norm.t())
    topk_values, topk_indices = similarity.topk(num_topk, dim=0)

# Read the image UUIDs and their ID numbers in the tensor from a file
image_UUIDs = []
with open(thisdir+'/image_UUIDs.dat', 'r') as f:
    for line in f.readlines():
        image_UUIDs.append(line.split(' ')[1].strip())

# Print the UUID of the top k results
for j in range(num_topk):
    print(image_UUIDs[topk_indices[j]])
