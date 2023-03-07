import json
import sys

from gerrychain import Graph
from gerrychain.tree import recursive_tree_part

N_DISTRICTS = 10
POP_VAR = "P1_001N"

infile = sys.argv[1]

with open(infile) as f:
    blocks = json.load(f)

pop_per_district = (
    sum(feature["properties"][POP_VAR] for feature in blocks["features"]) / N_DISTRICTS
)

graph = Graph.from_file(infile, ignore_errors=True)

seed_partition = recursive_tree_part(
    graph, range(N_DISTRICTS), pop_per_district, POP_VAR, 0.01
)

for i, feature in enumerate(blocks["features"]):
    feature["properties"]["district"] = seed_partition[i]

json.dump(blocks, sys.stdout)
