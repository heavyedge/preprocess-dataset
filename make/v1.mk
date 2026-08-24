.PHONY: dataset-v1 examples-v1 tests-v1

DATASETS_v1 := $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),dataset1,$(shell ls -d _data/v1/profiles/dataset* | xargs -n 1 basename))
PROFILES_v1 = $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),001,$(shell ls _data/v1/profiles/$(1)/*.tar.gz | xargs -n 1 basename -s .tar.gz))
SLURRIES_v1 := $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),G45,G50 G45 G40 G40IPA)

dataset-v1: \
$(foreach dataset,$(DATASETS_v1),datasets/v1/profiles/all_profiles/$(dataset).tar.gz) \
$(foreach dataset,$(DATASETS_v1),datasets/v1/profiles/mean_profiles/$(dataset).tar.gz) \
$(foreach slurry,$(SLURRIES_v1),datasets/v1/contact_angles/$(slurry).csv) \
$(foreach slurry,$(SLURRIES_v1),datasets/v1/viscosities/$(slurry).csv) \
$(foreach dataset,$(DATASETS_v1),datasets/v1/process_variables/all_profiles/$(dataset).csv) \
$(foreach dataset,$(DATASETS_v1),datasets/v1/process_variables/mean_profiles/$(dataset).csv)

examples-v1: $(wildcard examples/v1/*.ipynb)

tests-v1: $(patsubst examples/%,test/%,$(wildcard examples/v1/*.ipynb))

# Dataset

_temp/v1/profiles/all_profiles/%.h5: _data/v1/profiles/%.tar.gz config/v1/prep.yml
	@mkdir -p $(@D)
	rawdata=$$(mktemp -d)
	trap 'rm -rf $$rawdata' EXIT INT TERM
	tar -xzf $(word 1, $^) -C $$rawdata
	subdir=$$(ls $$rawdata)
	heavyedge prep --type=csvs --name=$* $$rawdata/$$subdir/HEAD_A --config $(lastword $^) -o $@
	echo 'Created $@'

define ALLPROFILES_v1
_temp/v1/profiles/all_profiles/$(1): $(foreach profile,$(call PROFILES_v1,$(1)),_temp/v1/profiles/all_profiles/$(1)/$(profile).h5)
endef
$(foreach dataset,$(DATASETS_v1),$(eval $(call ALLPROFILES_v1,$(dataset))))

datasets/v1/profiles/all_profiles/%.tar.gz: _temp/v1/profiles/all_profiles/%
	mkdir -p $(@D)
	tar -czf $@ -C $< .

_temp/v1/profiles/mean_profiles/%.h5: _temp/v1/profiles/all_profiles/%.h5 config/v1/mean.yml
	@mkdir -p $(@D)
	@filled=$$(mktemp)
	trap 'rm -rf $$filled' EXIT INT TERM
	heavyedge fill $< --config $(lastword $^) -o $$filled
	heavyedge mean $$filled --config $(lastword $^) -o $@
	echo 'Created $@'

define MEANPROFILES_v1
_temp/v1/profiles/mean_profiles/$(1): $(foreach profile,$(call PROFILES_v1,$(1)),_temp/v1/profiles/mean_profiles/$(1)/$(profile).h5)
endef
$(foreach dataset,$(DATASETS_v1),$(eval $(call MEANPROFILES_v1,$(dataset))))

datasets/v1/profiles/mean_profiles/%.tar.gz: _temp/v1/profiles/mean_profiles/%
	mkdir -p $(@D)
	tar -czf $@ -C $< .

datasets/v1/viscosities/G50.csv: scripts/v1/write-viscosity.py _data/v1/SlurryViscosities/Ascending/high_viscosity.csv _data/v1/SlurryViscosities/Descending/high_viscosity.csv
	mkdir -p $(@D)
	python3 $^ -o $@

datasets/v1/viscosities/G45.csv: scripts/v1/write-viscosity.py _data/v1/SlurryViscosities/Ascending/standard_viscosity.csv _data/v1/SlurryViscosities/Descending/standard_viscosity.csv
	mkdir -p $(@D)
	python3 $^ -o $@

datasets/v1/viscosities/G40.csv: scripts/v1/write-viscosity.py _data/v1/SlurryViscosities/Ascending/low_viscosity.csv _data/v1/SlurryViscosities/Descending/low_viscosity.csv
	mkdir -p $(@D)
	python3 $^ -o $@

datasets/v1/viscosities/G40IPA.csv: scripts/v1/write-viscosity.py _data/v1/SlurryViscosities/Ascending/low_surface_tension.csv _data/v1/SlurryViscosities/Descending/low_surface_tension.csv
	mkdir -p $(@D)
	python3 $^ -o $@

datasets/v1/contact_angles/%.csv: scripts/v1/read-ca.py _data/v1/ca/%
	mkdir -p $(@D)
	python3 $^ -o $@

_temp/v1/viscosities.csv: datasets/v1/viscosities/G50.csv datasets/v1/viscosities/G45.csv datasets/v1/viscosities/G40.csv datasets/v1/viscosities/G40IPA.csv
	mkdir -p $(@D)
	python3 -c "from pathlib import Path; import pandas as pd; paths = '$^'.split(' '); slurries = [Path(path).stem for path in paths]; dfs = [pd.read_csv(path).assign(slurry=slurry) for path, slurry in zip(paths, slurries)]; pd.concat(dfs, keys=slurries, names=['slurry']).to_csv('$@', index=False)"

_temp/v1/ContactAngles.yml: scripts/v1/write-ca.py datasets/v1/contact_angles/G50.csv datasets/v1/contact_angles/G45.csv datasets/v1/contact_angles/G40.csv datasets/v1/contact_angles/G40IPA.csv
	mkdir -p $(@D)
	python3 $^ --slurries HighViscosity Standard LowViscosity LowSurfaceTension -o $@

_temp/v1/process_variables/%.csv: scripts/v1/write-pv.py _data/v1/profiles/%/index.csv _temp/v1/viscosities.csv _data/v1/SlurryProperties _temp/v1/ContactAngles.yml datasets/v1/datapackage.json
	mkdir -p $(@D)
	python3 $^ -o $@

datasets/v1/process_variables/all_profiles/%.csv: scripts/v1/expand-pv.py _temp/v1/process_variables/%.csv _temp/v1/profiles/all_profiles/%
	mkdir -p $(@D)
	python3 $^ -o $@

datasets/v1/process_variables/mean_profiles/%.csv: scripts/v1/expand-pv.py _temp/v1/process_variables/%.csv _temp/v1/profiles/mean_profiles/%
	mkdir -p $(@D)
	python3 $^ -o $@

# Examples

examples/v1/profiles/all_profiles/dataset1/001.h5: datasets/v1/profiles/all_profiles/dataset1.tar.gz
	@mkdir -p $(@D)
	@tar -xzf $< -C $(@D) ./$(notdir $@)

examples/v1/profiles/mean_profiles/dataset1/001.h5: datasets/v1/profiles/mean_profiles/dataset1.tar.gz
	@mkdir -p $(@D)
	@tar -xzf $< -C $(@D) ./$(notdir $@)

examples/v1/viscosities.csv: $(foreach slurry,$(SLURRIES_v1),datasets/v1/viscosities/$(slurry).csv)
	mkdir -p $(@D)
	python3 -c '
	from pathlib import Path
	import pandas as pd

	SLURRIES = dict(G50="G50", G45="G45", G40="G40", G40IPA="G40+IPA")

	paths = [Path(path) for path in "$^".split(" ")]
	dfs = [pd.read_csv(path, dtype=str).assign(slurry=SLURRIES[path.stem]) for path in paths]
	pd.concat(dfs).to_csv("$@", index=False)
	'

examples/v1/process_variables.csv: $(foreach dataset,$(DATASETS_v1),datasets/v1/process_variables/mean_profiles/$(dataset).csv)
	mkdir -p $(@D)
	python3 -c '
	from pathlib import Path
	import pandas as pd

	paths = [Path(path) for path in "$^".split(" ")]
	dfs = [pd.read_csv(path, dtype=str).assign(dataset=path.stem) for path in paths]
	pd.concat(dfs).to_csv("$@", index=False)
	'

examples/v1/profile.ipynb: examples/v1/profiles/all_profiles/dataset1/001.h5 examples/v1/profiles/mean_profiles/dataset1/001.h5 .FORCE
	jupyter nbconvert --to notebook --execute --inplace $@

examples/v1/contact_angle.ipynb: datasets/v1/contact_angles/G50.csv datasets/v1/contact_angles/G45.csv datasets/v1/contact_angles/G40.csv datasets/v1/contact_angles/G40IPA.csv .FORCE
	jupyter nbconvert --to notebook --execute --inplace $@

examples/v1/viscosity.ipynb: examples/v1/viscosities.csv examples/v1/process_variables.csv .FORCE
	jupyter nbconvert --to notebook --execute --inplace $@

examples/v1/dimless.ipynb: examples/v1/process_variables.csv datasets/v1/datapackage.json .FORCE
	jupyter nbconvert --to notebook --execute --inplace $@

# Tests

test/v1/profile.ipynb: examples/v1/profiles/all_profiles/dataset1/001.h5 examples/v1/profiles/mean_profiles/dataset1/001.h5
	outfile=$$(mktemp)
	trap 'rm -rf $$outfile' EXIT INT TERM
	papermill examples/v1/profile.ipynb - -p profiles_path examples/v1/profiles/all_profiles/dataset1/001.h5 -p mean_profile_path examples/v1/profiles/mean_profiles/dataset1/001.h5 -p out_path $$outfile > /dev/null 2>&1
	[ -f "$$outfile" ]

test/v1/contact_angle.ipynb: datasets/v1/contact_angles/G50.csv datasets/v1/contact_angles/G45.csv datasets/v1/contact_angles/G40.csv datasets/v1/contact_angles/G40IPA.csv
	outfile=$$(mktemp)
	trap 'rm -rf $$outfile' EXIT INT TERM
	papermill examples/v1/contact_angle.ipynb - -p out_path $$outfile > /dev/null 2>&1
	[ -f "$$outfile" ]

test/v1/viscosity.ipynb: examples/v1/viscosities.csv examples/v1/process_variables.csv
	outfile=$$(mktemp)
	trap 'rm -rf $$outfile' EXIT INT TERM
	papermill examples/v1/viscosity.ipynb - -p viscosity_path examples/v1/viscosities.csv -p pv_path examples/v1/process_variables.csv -y "figsize: [12, 6]" -p out_path $$outfile > /dev/null 2>&1
	[ -f "$$outfile" ]

test/v1/dimless.ipynb: examples/v1/process_variables.csv datasets/v1/datapackage.json
	outfile=$$(mktemp)
	trap 'rm -rf $$outfile' EXIT INT TERM
	papermill examples/v1/dimless.ipynb - -p pv_path examples/v1/process_variables.csv -p metadata_path datasets/v1/datapackage.json -p out_path $$outfile > /dev/null 2>&1
	[ -f "$$outfile" ]
