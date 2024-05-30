import os
import json
from huggingface_hub import snapshot_download

def get_model_path(low_vram):
    if low_vram:
        return 'LanguageBind/MoE-LLaVA-StableLM-1.6B-4e-384'
    else:
        return 'LanguageBind/MoE-LLaVA-Phi2-2.7B-4e'

def download_model(model_path):
    print(f"Download model repository {model_path}")
    local_dir = snapshot_download(repo_id=model_path)
    print("Done")
    return local_dir

def load_config(local_dir):
    print("Load config.json")
    config_path = os.path.join(local_dir, 'config.json')
    with open(config_path, 'r', encoding='utf-8') as f:
        config = json.load(f)
    print(config)
    return config

def download_mm_image_tower(config):
    mm_image_tower = config['mm_image_tower']
    print(f"Download mm_image_tower model repository {mm_image_tower}")
    snapshot_download(repo_id=mm_image_tower)
    print("Done")

def download_taggers():
    print(f"Download tagger model repository SmilingWolf/wd-convnext-tagger-v3")
    snapshot_download(repo_id='SmilingWolf/wd-convnext-tagger-v3')
    print("Done")

    print(f"Download tagger model repository deepghs/wd14_tagger_with_embeddings")
    snapshot_download(repo_id='deepghs/wd14_tagger_with_embeddings')
    print("Done")

    print(f"Download tagger dataset repository alea31415/tag_filtering")
    snapshot_download(repo_id='alea31415/tag_filtering', repo_type='dataset')
    print("Done")

def main():
    low_vram = os.getenv('LOW_VRAM', '0') == '1'
    model_path = get_model_path(low_vram)
    local_dir = download_model(model_path)
    config = load_config(local_dir)
    download_mm_image_tower(config)
    download_taggers()

if __name__ == "__main__":
    main()