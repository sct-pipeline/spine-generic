## v2.6 (2020-12-03)
[View detailed changelog](https://github.com/spine-generic/spine-generic/compare/v2.5...v2.6)
 - Generate the interactive Plotly figures dynamically during documentation build.  [View pull request](https://github.com/spine-generic/spine-generic/pull/240)
 - Add interactive graphs in RTD (currently not working-- dependent on #240).  [View pull request](https://github.com/spine-generic/spine-generic/pull/237)
 - DOC: Remove duplicate Multi-center data entry.  [View pull request](https://github.com/spine-generic/spine-generic/pull/235)


## v2.5 (2020-10-02)
[View detailed changelog](https://github.com/spine-generic/spine-generic/compare/v2.4...v2.5)
 - sg_create_mosaic: Fix issues with modules compatibility; various improvements.  [View pull request](https://github.com/spine-generic/spine-generic/pull/229)
 - Force two decimal digits in regression box in t1-t2 agreement figure.  [View pull request](https://github.com/spine-generic/spine-generic/pull/228)
 - Compute min, max and median age across subjects.  [View pull request](https://github.com/spine-generic/spine-generic/pull/226)
 - Fix inconsistencies in proces_data.sh comments.  [View pull request](https://github.com/spine-generic/spine-generic/pull/224)
 - Add iframe to show good-quality data.  [View pull request](https://github.com/spine-generic/spine-generic/pull/218)


## v2.4 (2020-09-17)
[View detailed changelog](https://github.com/spine-generic/spine-generic/compare/v2.3...v2.4)

 - Round intra-site COV to first decimal for output statistics text..  [View pull request](https://github.com/spine-generic/spine-generic/pull/221)
 - List excluded sites into output txt file.  [View pull request](https://github.com/spine-generic/spine-generic/pull/217)
 - Cosmetic improvements with formatted output of statistics.  [View pull request](https://github.com/spine-generic/spine-generic/pull/215)
 - Exclude sites from ANOVA.  [View pull request](https://github.com/spine-generic/spine-generic/pull/213)
 - Sort metrics results to match sequence order in the spine-generic protocol.  [View pull request](https://github.com/spine-generic/spine-generic/pull/212)
 - Automatize text generation based on results.  [View pull request](https://github.com/spine-generic/spine-generic/pull/207)
 - Fix different x and y size in t1-t2 agreement figure.  [View pull request](https://github.com/spine-generic/spine-generic/pull/201)
 - Implement CI check for MTS scans.  [View pull request](https://github.com/spine-generic/spine-generic/pull/198)
 - Parameters checker now sets tolerance on the absolute (unsigned) difference.  [View pull request](https://github.com/spine-generic/spine-generic/pull/195)
 - Clarify output display for params checker.  [View pull request](https://github.com/spine-generic/spine-generic/pull/194)
 - Removed shell-based fetching of BIDS metadata for MTsat.  [View pull request](https://github.com/spine-generic/spine-generic/pull/192)
 - Add QC output for MT0->T1w and MT1->T1w registrations.  [View pull request](https://github.com/spine-generic/spine-generic/pull/188)
 - Changed location for output stats log file.  [View pull request](https://github.com/spine-generic/spine-generic/pull/186)
 - Compute ANOVAs and post-hoc tests across vendors and within vendors.  [View pull request](https://github.com/spine-generic/spine-generic/pull/185)


## v2.3 (2020-08-17)
[View detailed changelog](https://github.com/spine-generic/spine-generic/compare/v2.2...v2.3)

 - Delete publish.yml.  [View pull request](https://github.com/spine-generic/spine-generic/pull/175)


## v2.2 (2020-08-17)
[View detailed changelog](https://github.com/spine-generic/spine-generic/compare/v2.1.1...v2.2)

 - Fix issue when generating fig_t1_t2_agreement figures.  [View pull request](https://github.com/spine-generic/spine-generic/pull/161)
 - Fixed missing '-manual' after _seg suffix for manual corrs.  [View pull request](https://github.com/spine-generic/spine-generic/pull/133)
 - Use subprocess.run.  [View pull request](https://github.com/spine-generic/spine-generic/pull/174)
 - Use importlib.resources to access spinegeneric/flags/*.png.  [View pull request](https://github.com/spine-generic/spine-generic/pull/173)
 - Distribute packages properly.  [View pull request](https://github.com/spine-generic/spine-generic/pull/172)
 - Implement CI for checking data consistency.  [View pull request](https://github.com/spine-generic/spine-generic/pull/171)
 - Fix generate figure.  [View pull request](https://github.com/spine-generic/spine-generic/pull/167)
 - Fix superscript for MD and RD ylabel and remove a.u. unit for MTsat.  [View pull request](https://github.com/spine-generic/spine-generic/pull/164)
 - Improve qc defacing.  [View pull request](https://github.com/spine-generic/spine-generic/pull/162)
 - Added flag -qc-only; Major refactoring to simplify code.  [View pull request](https://github.com/spine-generic/spine-generic/pull/160)
 - Improve sg_manual_correction.  [View pull request](https://github.com/spine-generic/spine-generic/pull/158)
 - Exclude sub-mountSinai03 from some analyses.  [View pull request](https://github.com/spine-generic/spine-generic/pull/156)
 - Changed slicereg to centermass for DWI registration.  [View pull request](https://github.com/spine-generic/spine-generic/pull/154)
 - Improve sg_package_for_correction.  [View pull request](https://github.com/spine-generic/spine-generic/pull/149)
 - Update flags dict.  [View pull request](https://github.com/spine-generic/spine-generic/pull/147)
 - Generate QC report for manual corrections.  [View pull request](https://github.com/spine-generic/spine-generic/pull/146)
 - Create json sidecar.  [View pull request](https://github.com/spine-generic/spine-generic/pull/144)
 - Adding new function sg_params_checker to check acquisition parameters; Include it in CI.  [View pull request](https://github.com/spine-generic/spine-generic/pull/134)
 - Added spinegeneric in path for import.  [View pull request](https://github.com/spine-generic/spine-generic/pull/132)
 - New script to package data awaiting correction.  [View pull request](https://github.com/spine-generic/spine-generic/pull/129)
 - Fix help in manual_correction.py; file name instead of sub ID for labeling.  [View pull request](https://github.com/spine-generic/spine-generic/pull/127)
 - Convert to proper Python package.  [View pull request](https://github.com/spine-generic/spine-generic/pull/121)
 - Adding script to copy label file into derivatives/labels/sub-XXX/anat.  [View pull request](https://github.com/spine-generic/spine-generic/pull/118)
 - Ensures reproducible pipeline across OSs; various improvements.  [View pull request](https://github.com/spine-generic/spine-generic/pull/115)
 - Check if file exists before copying.  [View pull request](https://github.com/spine-generic/spine-generic/pull/109)
 - New script to copy manual corrections under derivatives/.  [View pull request](https://github.com/spine-generic/spine-generic/pull/106)
 - Look for manual files under derivatives/.  [View pull request](https://github.com/spine-generic/spine-generic/pull/104)
 - manual_correction.py script.  [View pull request](https://github.com/spine-generic/spine-generic/pull/103)
 - Documentation updates.  [View pull request](https://github.com/spine-generic/spine-generic/pull/122)
 - switch from relative to absolute links in documentation.  [View pull request](https://github.com/spine-generic/spine-generic/pull/102)
