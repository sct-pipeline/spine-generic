#!/usr/bin/env python
#
# Automatically generate a figure for generic spine data displaying metric values for a specified contrast
# (t1, t2, dmri, mt, or gre-me). Results (csv and png) are output in the folder specified by -p.
#
# USAGE:
#   ${SCT_DIR}/python/bin/python generate_figure.py -p PATH_DATA -c {t1, t2, dmri, mt, t2s} -l IND_LEVELS
#
#   Help:
#   ${SCT_DIR}/python/bin/python generate_figure.py -h
#
#   Example:
#   ${SCT_DIR}/python/bin/python generate_figure.py -p ~/data/spine_generic/ -c t1 -l 0,1
#
# OUTPUT:
# results_per_center.csv: metric results for each center
# Figure displaying results across centers
#
# DEPENDENCIES:
# - SCT
#
# Authors: Stephanie Alley, Julien Cohen-Adad
# License: https://github.com/neuropoly/sct_pipeline/spine_generic/blob/master/LICENSE

# TODO: make -c mandatory

import os, argparse
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import logging
from collections import OrderedDict

log = logging.getLogger()

# Create a dictionary of centers: key: folder name, value: dataframe name
centers = {
    'chiba_spine-generic_20180608-750': 'Chiba-750',
    'juntendo-750w_spine-generic_20180529': 'Juntendo-750w',
    'tokyo-univ_spine-generic_20180604-750w': 'TokyoUniv-750w',
    'tokyo-univ_spine-generic_20180604-signa1': 'TokyoUniv-Signa1',
    'tokyo-univ_spine-generic_20180604-signa2': 'TokyoUniv-Signa2',
    'ucl_spine-generic_20171207': 'UCL-Achieva',
    'juntendo-achieva_spine-teneric_20180524': 'Juntendo-Achieva',
    'glen_spine-generic_20171128': 'Glen-Ingenia',
    'tokyo-univ_spine-generic_20180604-ingenia': 'TokyoUniv-Ingenia',
    'chiba_spine-generic_20180608-ingenia': 'Chiba-Ingenia',
    'mgh-bay3_spine-generic_20171201': 'MGH-Trio',
    'douglas_spine-generic_20171127': 'Douglas-Trio',
    'poly_spine-generic_20171221': 'Polytechnique-Skyra',
    'juntendo-skyra_spine-generic_20180509': 'Juntendo-Skyra',
    'tokyo-univ_spine-generic_20180604-skyra': 'TokyoUniv-Skyra',
    'unf_sct_026': 'UNF-Prisma',
    'oxford_spine-generic_20171209': 'Oxford-Prisma',
    'juntendo-prisma_spine-generic_20180523': 'Juntendo-Prisma',
}

# because dictionaries are unsorted, we need to create another list to sort them
centers_order = [
    'chiba_spine-generic_20180608-750',
    'juntendo-750w_spine-generic_20180529',
    'tokyo-univ_spine-generic_20180604-750w',
    'tokyo-univ_spine-generic_20180604-signa1',
    'tokyo-univ_spine-generic_20180604-signa2',
    'ucl_spine-generic_20171207',
    'juntendo-achieva_spine-teneric_20180524',
    'glen_spine-generic_20171128',
    'tokyo-univ_spine-generic_20180604-ingenia',
    'chiba_spine-generic_20180608-ingenia',
    'mgh-bay3_spine-generic_20171201',
    'douglas_spine-generic_20171127',
    'poly_spine-generic_20171221',
    'juntendo-skyra_spine-generic_20180509',
    'tokyo-univ_spine-generic_20180604-skyra',
    'unf_sct_026',
    'oxford_spine-generic_20171209',
    'juntendo-prisma_spine-generic_20180523',
]

# color to assign to each MRI model for the figure
colors = {
    '750': 'black',
    'Signa': 'black',
    'Ingenia': 'dodgerblue',
    'Achieva': 'dodgerblue',
    'Trio': 'limegreen',
    'Skyra': 'limegreen',
    'Prisma': 'limegreen',
}

# path to metric based on contrast
file_metric = {
    't1': 'csa/csa_mean.xls',
    't2': 'csa/csa_mean.xls',
    'dmri': 'fa.xls',
    'mt': 'mtr.xls',
    't2s': 'csa_gm/csa_mean.xls',
}

# contrast-dependent key to dataframe
key_metric = {
    't1': 'MEAN across slices',
    't2': 'MEAN across slices',
    'dmri': 'Metric value',
    'mt': 'Metric value',
    't2s': 'MEAN across slices',
}

# ylabel
ylabel = {
    't1': 'Cord CSA ($mm^2$)',
    't2': 'Cord CSA ($mm^2$)',
    'dmri': 'FA',
    'mt': 'MTR (%)',
    't2s': 'Gray Matter CSA ($mm^2$)',
}

# ylim for figure
ylim = {
    't1': [40, 90],
    't2': [40, 90],
    'dmri': [0.4, 0.9],
    'mt': [30, 65],
    't2s': [10, 20],
}


# ystep (in yticks) for figure
ystep = {
    't1': 5,
    't2': 5,
    'dmri': 0.1,
    'mt': 5,
    't2s': 1,
}


def get_parameters():
    parser = argparse.ArgumentParser(description='Generate a figure to display metric values across centers.')
    parser.add_argument("-p", "--path",
                        help="Path that contains all subjects.")
    parser.add_argument("-c", "--contrast",
                        choices=['t1', 't2', 'dmri', 'mt', 't2s'],
                        help="Contrast for which figure should be generated.")
    parser.add_argument("-l", "--levels",
                        help='Vertebral levels to include (will average them all). Separate with ",". If a level is '
                             'missing it will be ignored in the averaging. Example: -l 2,3,4')
    args = parser.parse_args()
    return args


def get_color(center_name):
    """
    Find color based on MRI system
    :param center_name: should include MRI vendor model
    :return: str: color for colorbar
    """
    for system, color in colors.iteritems():
        if system in center_name:
            return color


def main():
    # # go to folder that contails all data
    # os.chdir(path_data)
    # # list all directories
    # folder_dir = os.path.abspath(os.curdir)  # '/Volumes/projects/generic_spine_procotol/data'
    file_output = os.path.join(path_data, 'results_'+contrast+'_levels'+levels+'.csv')

    # parse levels
    ind_levels = map(int, levels.split(','))  # split string into list and convert to list ot int

    # order centers dictionary for custom display
    centers_ordered = OrderedDict(sorted(centers.items(), key=lambda i: centers_order.index(i[0])))

    # Initialize pandas series
    results_per_center = pd.Series(index=centers_ordered.values())

    list_colors = []
    # Generate figure and results file for contrast
    # if contrast == 't1':
    for folder_center, name_center in centers_ordered.iteritems():
        # Read in metric results for contrast
        try:
            data = pd.read_excel(os.path.join(path_data, folder_center, contrast, file_metric[contrast]))
            # Add results to dataframe
            # loop across indexes-- ignore missing levels (if poor coverage)
            data_temp = []
            for i in ind_levels:
                try:
                    data_temp.append(data[key_metric[contrast]].values[i])
                except IndexError as error:
                    logging.warning(error.__class__.__name__ + ": " + error.message)
                    logging.warning("Folder: " + folder_center + ". Level {} is missing.".format(i))
            results_per_center[name_center] = np.mean(data_temp)
            list_colors.append(get_color(name_center))
        except IOError as error:
            logging.warning(error)
            logging.warning("Removing this center for the figure generation: {}".format(folder_center))
            results_per_center = results_per_center.drop(name_center)
            centers_ordered.pop(folder_center)

    # Write results to file
    results_per_center.to_csv(file_output)

    # Generate figure for results
    fig, ax = plt.subplots(figsize=(12, 8))
    results_per_center.plot(kind='bar', color=list_colors, legend=False, fontsize=15, align='center')
    # fig.set_xlabel("Center", fontsize=15, rotation='horizontal')
    plt.setp(ax.xaxis.get_majorticklabels(), rotation=45, ha="right")  # rotate xticklabels at 45deg and align at end
    ax.set_xticklabels(centers_ordered.values())
    plt.ylabel(ylabel[contrast], fontsize=15)
    plt.ylim(ylim[contrast])
    plt.yticks(np.arange(ylim[contrast][0], ylim[contrast][1], step=ystep[contrast]))
    plt.grid(axis='y')
    plt.title(contrast)
    plt.tight_layout()  # make sure everything fits
    plt.savefig(os.path.join(path_data, 'fig_'+contrast+'_levels'+levels+'.png'))
    # plt.show()


if __name__ == "__main__":
    args = get_parameters()
    path_data = args.path
    contrast = args.contrast
    levels = args.levels
    main()
