# elected-school-board-maps
Maps for the Chicago elected school board

* Law: https://www.ilga.gov/legislation/ilcs/ilcs4.asp?DocName=010500050HArt%2E+34&ActID=1005&ChapterID=17&SeqStart=196400000&SeqEnd=222800000

# todo 
- [x] create initial seed partition of 10 districts of roughly equal population
- [ ] add VRA considerations https://mggg.org/publications/VRA-Ensembles.pdf
  - [x] assign CVAP race to precincts: https://www.census.gov/programs-surveys/decennial-census/about/voting-rights/cvap.html
  - [x] Ecological inference: https://github.com/mggg/VRA_ensembles/blob/master/EI_Note.pdf
  - [ ] Adapt gerrychain to generate VRA comppatible districts https://github.com/mggg/VRA_ensembles
- [ ] add roughly equal CPS population considerations
- [ ] check if we need to add minimum number of schools

## to build
```console
pip install -r requirements.txt
make
```
