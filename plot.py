#!/usr/bin/env python3
import os
import sys
import argparse
import pathlib
import pandas
import matplotlib.pyplot as plt
from os.path import join, exists, abspath, dirname

parser = argparse.ArgumentParser()
parser.add_argument('target', type=str)
args = parser.parse_args()

drifuzz_path = dirname(abspath(__file__))

model_data_file = join(drifuzz_path, 'results', f'result-{args.target}-0-1-NNN', f'work-{args.target}-model', 'evaluation', 'data.csv')
random_data_file = join(drifuzz_path, 'results', f'result-{args.target}-0-0-NNN', f'work-{args.target}-random','evaluation', 'data.csv')
random_concolic_data_file = join(drifuzz_path, 'results', f'result-{args.target}-1-0-NNN', f'work-{args.target}-conc','evaluation', 'data.csv')
model_concolic_data_file = join(drifuzz_path, 'results', f'result-{args.target}-1-1-NNN', f'work-{args.target}-conc-model','evaluation', 'data.csv')

out_file = args.target + '.pdf'
dfs = []
lgs = []
titles = [
    'time',
    'performance',
    'hashes',
    'path_pending',
    'favorites',
    'panics',
    'panics_unique',
    'kasan',
    'kasan_unique',
    'reloads',
    'reloads_unique',
    'level',
    'cycles',
    'fav_pending',
    'blacklisted',
    'total',
    'byte_covered',
]

data_files = [
    random_data_file,
    random_concolic_data_file,
    model_data_file,
    model_concolic_data_file,
]

settings = [
    'random seed',
    'random seed +concolic',
    'generated seed',
    'generated seed +concolic',
]

colors = [
    'grey',
    'green',
    'blue',
    'red',
]
def median_of_three(l):
    a = l[0]
    b = l[1]
    c = l[2]
    if a <= b and b <= c:
        return 1
    if c <= b and b <= a:
        return 1
    if a <= c and c <= b:
        return 2
    if b <= c and c <= a:
        return 2
    return 0

def plot(x, label):
    fig = plt.figure()
    ax = fig.add_subplot(1,1,1)
    bests = []

    for i in range(4):
        values = []
        dfs = []
        for iteration in range(3):
            data_file = str(data_files[i]).replace("NNN", str(iteration+1))
            if exists(data_file):
                df = pandas.read_csv(
                                data_file,
                                sep=';',
                                names=titles,
                                index_col=False)
                df['time'] /= 3600
                df['time'] *= 96
                # Offset seed generation time
                if i >= 2:
                    df['time'] += 3
                # Select a point every 1 core-hour
                df = df.iloc[::150, :]
                # print(f'Value: {df.tail(1)[x].item()}')
                values.append(df.tail(1)[x].item())
                dfs.append(df)
        if len(values) == 3:
            median_index = median_of_three(values)
            bests.append(len(bests) *3 + median_index)
            for ind,df in enumerate(dfs):
                if ind == median_index:
                    ax = df.plot('time', x, ax=ax, color=colors[i],
                                label=settings[i])
                else:
                    ax = df.plot('time', x, ax=ax, color=colors[i],
                                label=settings[i], style=[':'])
        else:
            for df in dfs:
                ax = df.plot('time', x, ax=ax, color=colors[i],
                                label=settings[i])

    handles, labels = ax.get_legend_handles_labels()
    ax.legend([handle for i,handle in enumerate(handles) if i in bests],
        [label for i,label in enumerate(labels) if i in bests], loc = 'best')

    plt.title(args.target)
    plt.xlabel('Time (core-hour)')
    plt.ylabel(label)

    fig = ax.get_figure()
    fig.savefig(f'plots/{args.target}_{x}.pdf')

    plt.clf() 
    plt.gcf()
    plt.close()

plot('byte_covered', 'Coverage (bytes)')
plot('hashes', 'Number of Paths')