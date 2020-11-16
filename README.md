# Test Factorial Mass Univariate ERP Toolbox (FMUT)

I tested the [Factorial Mass Univariate ERP Toolbox (FMUT)](https://github.com/ericcfields/FMUT) with data from a previous ERP study ([materials](https://doi.org/10.17605/OSF.IO/C7G9Y), [paper](https://doi.org/10.1038/s41598-018-30701-5)). Many thanks to [Eric Fields](https://github.com/ericcfields) for this great toolbox!

## Procedure

- Clone or download this repository
- Download the raw data (available on the [Open Science Framework](https://osf.io/psv6m/)) and put them in the [*./data/raw/*](https://github.com/aschetti/test_FMUT/tree/main/data/raw) subfolder
- Run MATLAB
- Verify that you have installed [EEGLAB](https://github.com/sccn/eeglab), [ERPLAB](https://github.com/lucklab/erplab), [Mass Univariate ERP Toolbox](https://github.com/dmgroppe/Mass_Univariate_ERP_Toolbox), and [FMUT](https://github.com/ericcfields/FMUT) (see respective instructions)
- Open [`test_FMUT.m`](https://github.com/aschetti/test_FMUT/blob/main/scripts/test_FMUT.m), located in the [./scripts](https://github.com/aschetti/test_FMUT/tree/main/scripts) subfolder
- Change the `path_project` variable (line 12) according to your home path
- Run `test_FMUT.m`

## Session Information:

- Ubuntu 20.10
- EEGLAB 2020.0
- ERPLAB 8.02
- Mass Univa​riate ERP Toolbox 1.25.0.0
- FMUT 0.5.1
