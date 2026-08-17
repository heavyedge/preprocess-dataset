# Edge Profile Dataset
[![HuggingFace](https://img.shields.io/badge/HuggingFace-Dataset-orange?logo=huggingface)](https://huggingface.co/datasets/heavyedge/profiles)
[![GitHub repository](https://img.shields.io/badge/github-repo-blue?logo=github)](https://github.com/heavyedge/profile-dataset)

Preprocessed edge profile dataset.

Provides:
  - Coating edge profile data.
  - Process variables corresponding to each edge profile.
  - Example notebooks

## Usage

This repository provides scripts to preprocess each version of raw dataset and notebooks to visualize the preprocessed data.

### Cloning the repository

You need:

- `git`
- Python runtime with `pip`

Run the following commands to clone the repository and install the necessary requirements.

```sh
git clone git@github.com:heavyedge/profile-dataset.git
cd profile-dataset
pip install -r requirements.txt
```

### Downloading the raw dataset (Optional)

Run the following commands to download the raw dataset in the `_data` directory.

```sh
export PROFILES_V1_GDRIVE="..."
export CA_V1_GDRIVE="..."
./setup.sh
```

### Acquiring the preprocessed data

The preprocessed data built by this project can be acquired by downloading it directly from the [dataset repository](https://huggingface.co/datasets/heavyedge/profiles).
Alternatively, you can perform the preprocessing yourself if you have downloaded the raw dataset.

Either approach creates the preprocessed data in the `datasets` directory.

#### Direct download

You need:

- [Hugging Face CLI](https://huggingface.co/docs/transformers/en/installation)

Run the following command:

```sh
hf download heavyedge/profiles --repo-type dataset --local-dir datasets
```

#### Building the dataset

You need:

- `make`

Run the following command:

```sh
make datasets
```

Each `datasets/v*` directory stores preprocessed profiles from the corresponding major version of raw profile dataset.

### Acquiring the built examples

The preprocessed data are visualized as notebooks in the `examples` directory.

The notebook outputs are stripped before being stored in this repository.
To check their outputs, you must acquire the built example notebooks.

You can either download the built notebooks from the [GitHub release](https://github.com/heavyedge/profile-dataset/releases) artifacts, or build the notebooks yourself if you have acquired the preprocessed data.

#### Building the notebooks

You need:

- `make`

```sh
pip install -r examples/requirements.txt
make examples
```

### Testing

```sh
pip install -r requirements.txt -r examples/requirements.txt
make tests
```

## Contributing

### Configuring git

Configure the local git filter (run once after cloning):

```sh
nbstripout --install --attributes .gitattributes
git config filter.nbstripout.clean "nbstripout"
git config filter.nbstripout.smudge cat
git config filter.nbstripout.required true
```

### Testing

Setting the `HEAVYEDGE_TEST_MODE` environment variable to `1` builds only a small subset of data for testing purposes.

```sh
HEAVYEDGE_TEST_MODE=1 make
```

### Building the container image

The `Dockerfile` is provided to facilitate data distribution without sharing secrets.

After downloading the raw dataset and building the preprocessed data and examples, build the image with one of the following targets:

- `base` (default)
  - Includes the preprocessed dataset (`datasets`).
  - Includes the built examples (`examples`).
  - Includes non-hidden source files.
- `dev`
  - Includes the raw dataset (`_data`).
  - Includes the preprocessed dataset (`datasets`).
  - Includes the built examples (`examples`).
  - Includes all source files.

### Versioning policy

This repository follows semantic versioning with [Python version specifiers](https://packaging.python.org/en/latest/specifications/version-specifiers/):

```
N.N.N[{a|b|rc}N][.postN][.devN]
```

- Major version is raised when the dataset API is changed in a backwards-incompatible way.
- Minor version is raised when new dataset is added.
- Patch version is raised when bugs are fixed.

> **NOTE**: The major version is raised only when the dataset is changed in a backward-incompatible way.
> When new data is added, minor version is raised with new `datasets/v*` directory.
