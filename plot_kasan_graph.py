#!/usr/bin/env python3
import matplotlib.pyplot as plt
import numpy as np
import os

os.system("mkdir -p plots")
data_file = open('kasan_opt_data', 'r')

lines = data_file.readlines()
noopt = {}
opt = {}
targets = []
for line in lines:
    sp = line.split(' ')
    target = sp[0]
    val = float(sp[1])
    if target not in targets:
        targets.append(target)
    if target in noopt and len(noopt[target]) < 3:
        noopt[target].append(val)
    elif target not in noopt:
        noopt[target] = [val]
    elif target not in opt:
        opt[target] = [val]
    elif target in opt and len(opt[target]) < 3:
        opt[target].append(val)
optmeds = []
nooptmeds = []
for t in targets:
    print(f"Target: {t}")
    assert len(opt[t]) == 3
    assert len(noopt[t]) == 3
    optmed = sorted(opt[t])[1]
    nooptmed = sorted(noopt[t])[1]
    # optmeds.append(optmed)
    # nooptmeds.append(nooptmed)
    # Normalized
    optmeds.append(1)
    nooptmeds.append(nooptmed/optmed)

print("Targets: ", targets)
print("Opt medians: ", optmeds)
print("Noopt medians: ", nooptmeds)

width = 0.35
x = np.arange(len(targets))  # the label locations
fig, ax = plt.subplots()

rects1 = ax.bar(x - width/2, optmeds, width, label='Optimized')
rects2 = ax.bar(x + width/2, nooptmeds, width, label='Unmodified')

ax.set_xticks(x)
ax.set_xticklabels(targets)
ax.legend()

fig = ax.get_figure()
fig.savefig("plots/kasan.png")

plt.clf() 
plt.gcf()
plt.close()

def geo_mean(iterable):
    a = np.array(iterable)
    return a.prod()**(1.0/len(a))

print("Geometric means: ", geo_mean(nooptmeds))
