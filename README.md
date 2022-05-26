---
title: dbGaP
namespace: dbGaP
description: The database of Genotypes and Phenotypes (dbGaP) was developed to archive and distribute the data and results from studies that have investigated the interaction of genotype and phenotype in Humans.
dependencies:
  - name: dbGaP
    url: https://ftp.ncbi.nlm.nih.gov/dbgap/studies/
---

<a href="https://github.com/biobricks-ai/dbGaP/actions"><img src="https://github.com/biobricks-ai/dbGaP/actions/workflows/bricktools-check.yaml/badge.svg?branch=main"/></a>

## Documentation Files
Documentation files are included by dbGaP. They describe the studies and data formatting

``data/dbGaPStudyComponents.pdf`` describes ID formatting. Ids that include **phs** correspond to the study, such as ``phs000000.v1.p1``. IDs that include **pha**, such as ``pha000000.1``, correspond to the association analyses. 
```
dvc get git@github.com:insilica/oncindex-bricks.git bricks/dbGaP/data/dbGaPStudyComponents.pdf -o data/dbGaPStudyComponents.pdf
```
``data/HighLevelDataModel.pdf`` discusses the difference between public and controlled access data types
```
dvc get git@github.com:insilica/oncindex-bricks.git bricks/dbGaP/data/HighLevelDataModel.pdf -o data/HighLevelDataModel.pdf
```
``dbGaPRelationalIDs.pdf`` discusses dbGaP Identifiers
```
dvc get git@github.com:insilica/oncindex-bricks.git bricks/dbGaP/data/dbGaPRelationalIDs.pdf -o data/dbGaPRelationalIDs.pdf
```

## Variant association studies data
Variant association data files are combined into parquet files from different studies. 
The variant association files are split into 150 files, each file containing a columns
``Note: combined data set is ~ 50GB``

#### Study information Columns per variant association data
Information for each study is included as separate columns in each of the variant association files. 
* *NCBI dbGaP analysis accession:* Accession ID  
* *Name:* Name for study
* *Description:*  Description of study
* *Method:*  Method for study
* *Human genome build:* Genome build
* *dbSNP build:*  dbSNP build for variants

#### Column IDs for variant assocation file
* SNP ID: Marker accession
* P-value:  testing p-value
* Chr ID: chromosome
* Chr Position: chromosome position
* ss2rs:  ss to rs orientation.  +: same; -: opposite strand.
* rs2genome:  Orientation of rs flanking sequence to reference genome.  +: same orientation, -: opposite.
* Allele1:  genomic allele 1
* Allele2:  genomic allele 2
* pHWE (case):  p-value from HWE testing in cases
* pHWE (control): p-value from HWE testing in controls
* Call rate (case): Call rate for cases
* Call rate (control):  Call rate for controls
* CI low: the lower limit of 95% confidence interval
* CI high:  the higher limit of 95% confidence interval

## Overview Data dbGaP

``data/Analysis_Table_of_Contents.parquet``: Links phs ID, pha ID, and study info to downloaded variant association files.
``data/PheGenIDump.20170814.parquet``: Indicates phenotype relationships between datasets. Also includes variant and pubmed data

**Describes grouping of datasets and studies**
``data/analysisGrouping.parquet``
``data/datasetGrouping.parquet``
``data/documentsGrouping.parquet``
``data/variableGrouping.parquet``

