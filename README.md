## How to install:
### Mac:
Open Terminal and execute the following three commands:
1. Install Homebrew \
`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
2. Install Python (and pip) \
`brew install python`
3. Install the required Python modules\
`pip3 install pip pillow torch open_clip_torch`
4. Continue to the steps listed under "Both"


### Windows:
Open the command prompt and execute the following four commands:
1. Install Windows  Subsystem for Linux, aka WSL (sadly, this is necessary because PyTorch does not support Windows):\
`wsl --install`
2. Open WSL (then execute steps 3 and 4 within WSL)\
`wsl`
3. Install the Python package manager pip\
`sudo apt install python3-pip`
4. Install the required Python modules:\
`pip3 install pip pillow torch open_clip_torch`
5. Continue to the steps listed under "Both"



### Both:
1. Download this repository.
2. In Lightroom click File > Plug-in Manager > Add and navigate to the download location of the repository and select the plug-in folder  "LRC_semantic_search.lrdevplugin"
3. Then click File > Plug-in Extras > Export for search\
The third step will build the search index, which may take quite a while depending on the size of your catalog (you will see a progress bar at the top left of Lightroom). After that you can use the search functions from the Library menu under Library > Plug-in Extras > Search by text or Search similar images


### NOTE: 
The initial run of "Export for search" will download a pre-trained AI model for open_clip, which may take a while. After this, the plug-in does not require an internet connection. Your photos will NEVER be uploaded anywhere. The search engine operates entirely locally on your device.
