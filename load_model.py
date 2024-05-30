import os
import json
from huggingface_hub import snapshot_download

low_vram = os.getenv('LOW_VRAM', '0') == '1'

if low_vram:
    model_path = 'LanguageBind/MoE-LLaVA-StableLM-1.6B-4e-384'
else:
    model_path = 'LanguageBind/MoE-LLaVA-Phi2-2.7B-4e'

print(f"Download model repository {model_path}")

local_dir = snapshot_download(repo_id=model_path)

print("Done")

print("Load config.json")
config_path = os.path.join(local_dir, 'config.json')
with open(config_path, 'r', encoding='utf-8') as f:
    config = json.load(f)
print(config)

mm_image_tower = config['mm_image_tower']

print(f"Download mm_image_tower model repository {mm_image_tower}")
snapshot_download(repo_id=mm_image_tower)
print("Done")
