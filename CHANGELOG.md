# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.2] 2024-04-24

### Fixed

- fixed a bug in the `sc2rf` tables that can crash the HTML summary report
  - see [#71](https://github.com/rki-mf1/CoVpipe2/issues/71) and [#72](https://github.com/rki-mf1/CoVpipe2/issues/72)

## [0.5.1] 2024-03-15

### Added

- new parameters for genome QC: `seq_threshold` and `n_threshold`
  - the default values did not change

## [0.5.0] 2024-03-13

### Changed

- updated default `nextclade` version to `3.3.1`
  - default dataset version `2024-02-16--04-00-32Z`
- updated default `pangolin` version to `4.3`
  - default `pangolin-data` version 1.25.1

## [0.4.3] 2023-06-26

### Fixed

- fixed conda channel order
- enhanced nextclade dataset provenance

## [0.4.2] 2023-06-08

### Added

- added a DOI

## [0.4.1] 2023-05-23

### Changed

- update documentation

## [0.4.0] 2023-05-09

### Added

- new parameters `nextclade_dataset_name` and `nextclade_dataset_tag` for better `nextclade` fine tuning
  - with `--update` the latest dataset tag is selected
- new filter for indels for consensus generation based on their frequency `--cns_indel_filter`

### Fixed

- fixed conda/mamba execution in standard profile

### Changed

- updated smallest required `nextflow` version to `22.10.0`

## [0.3.4] 2023-04-13

### Changed

- updated default `nextclade` version to 2.13.1
- updated default `pangolin` version to 4.2 with `pangolin-data` version 1.18.1.1

### Fixed

- corrected column name in summary report table

## [0.3.3] 2023-03-10

### Added

- timestamp in report name

## [0.3.2] 2023-02-08

### Fixed

- updated conda config

## [0.3.1] 2022-12-20

### Added

- added license (GPL3)

### Changed

- `sc2rf` resources from https://github.com/ktmeaton/ncov-recombinant instead of https://github.com/lenaschimmel/sc2rf

## [0.3.0] 2022-12-14

### Added

- test profile
- end-to-end CI test

### Fixed

- Report (accumulated sequence depth plot) can handle > 90 input samples

### Changed

- default reference changed from none to 'sars-cov-2'

## [0.2.9] 2022-11-03

### Added

- full support for single end data

## [0.2.8] 2022-09-19

### Added

- '--bamclipper_additional_parameters' option to adjust BAMClipper parameters
- documentation on how names in the input BED file have to be to automatically generate a BEDPE file
- added `pangolin-data` version to th epangolin environment/container 
- added an insert size filter for the BAM file

### Fixed

- RKI report bug

## [0.2.7] 2022-08-23

### Fixed

- fixed Nextclade2 Docker auto-update

### Changed

- updated Nextclade to version 2: CoVpipe2 not compatible with nextclade version `< 2.4.0`
- updated Pangolin to version 4.1.2

### Removed

- parameter `pangolin_scorpio`, since pangolin default behaviour changed from [v4.1](https://github.com/cov-lineages/pangolin/releases/tag/v4.1)

## [0.2.6] 2022-07-27

### Fixed

- report can handle Kraken2 output with no human, unclassified or tax_id reads

## [0.2.5] 2022-07-19

### Changed

- changed `bcftools consensus` parameter from `-I` to `-H I`
  - does not change behaviour
- genotype adjustment for all heterzygote variants
- updated default pangolin version to 4.0.6
- renamed parameter `pangolin_skip_scorpio` to `pangolin_scorpio` (default behavior of skipping scorpio does not change)
- Kraken2 read output is not compressed - changed the file naming accordingly

### Removed

- removed unsued script
- removed unused conda yamls

## [0.2.4] 2022-06-14

### Added

- added sc2rf 
  - strict params to find potential recombinants
- added skip-scorpio parameter for pangolin
  - activeted per defaul
- added this changelog

### Changed

- separate result tabled get published
- better primer/reference id check
  - fist fasta id has to be at least once in the primer file (some primer kits have a non-sc2 amplicon)

## [0.2.3] 2022-06-01

### Changed

- kraken2 database can be set by user
- hard filtered variants get published in the variant calling result directory

### Removed

- removed `?` removal since deletion adjustment is removed
- update processes for pangolin and nextclade

### Fixed

- fixed container execution for pangolin and nextclade
- fixed disabling/enabling of `var_sap` parameter

## [0.2.2] 2022-06-01

### Changed

- updated workflow figure
- more stable automated conda update for pangolin and nextclade directly from anaconda.org
- updated help/readme

### Removed

- removed deletion adjustment since bcftools works as expected

## [0.2.1] 2022-05-09

### Added

- LCS update functionality

## [0.2.0] 2022-05-05

### Added

- LCS fro mixed sample detection

### Changed

- updated versions of samtools, liftoff, kraken, freebayes, bcftools, fastp, bedtools

### Fixed

- `bedtools subtract` instead of `intersect` for low coverage mask generation

## [0.1.2] 2022-04-13

### Changed

- updated help and readme
- disabel `var-sap` in default
- removed workflow version from consensus fasta header

## [0.1.1] 2022-04-07

- fixed krona fails with mamba/conda execution
- fixes pangolin update
- update nextclade

## [0.1.1-alpha] 2022-04-07

### Added

- DESH support

## [0.1.0-alpha] 2022-04-06

- initial commit
