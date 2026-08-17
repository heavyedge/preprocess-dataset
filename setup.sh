#!/bin/sh

pip install uv

uv pip install --system 'gdown<6.0.0'
mkdir -p ./_data/v1/profiles ./_data/v1/ca

(
  uv pip install --system -r requirements.txt -r examples/requirements.txt
) &
requirements_pid=$!

(
  gdown --fuzzy "$PROFILES_V1_GDRIVE" -O ./_data/v1/profiles.tar
  tar -xf _data/v1/profiles.tar -C _data/v1/profiles
  mv _data/v1/profiles/SlurryProperties _data/v1/profiles/SlurryViscosities _data/v1/
) &
profiles_pid=$!

(
  gdown --fuzzy "$CA_V1_GDRIVE" -O ./_data/v1/ca.tar
  tar -xf _data/v1/ca.tar -C _data/v1/ca
) &
ca_pid=$!

wait "$requirements_pid"
wait "$profiles_pid"
wait "$ca_pid"
