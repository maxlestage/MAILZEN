#!/usr/bin/env bash
# Downloads the public datasets used by train.py into the folder given (data/ by default).
# - all-scam-spam (Apache-2.0): https://huggingface.co/datasets/FredZhang7/all-scam-spam
# - phishing-dataset, texts and urls (Apache-2.0): https://huggingface.co/datasets/ealvaradob/phishing-dataset
# - SMS Spam Collection (CC BY 4.0): https://archive.ics.uci.edu/dataset/228/sms+spam+collection
set -euo pipefail
out="${1:-data}"
mkdir -p "$out/sms"
curl -sSfL -o "$out/junk.csv" "https://huggingface.co/datasets/FredZhang7/all-scam-spam/resolve/main/junkmail_dataset.csv"
curl -sSfL -o "$out/texts.json" "https://huggingface.co/datasets/ealvaradob/phishing-dataset/resolve/main/texts.json"
curl -sSfL -o "$out/urls.json" "https://huggingface.co/datasets/ealvaradob/phishing-dataset/resolve/main/urls.json"
curl -sSfL -o "$out/sms.zip" "https://archive.ics.uci.edu/static/public/228/sms+spam+collection.zip"
python3 -c "import zipfile, sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$out/sms.zip" "$out/sms"
echo "Data ready in $out: python3 train.py --data $out"
