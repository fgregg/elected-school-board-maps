import sys

from gerrychain import Graph, GeographicPartition, constraints
from gerrychain.updaters import Tally, cut_edges
from gerrychain import MarkovChain
from gerrychain.proposals import recom
from gerrychain.accept import always_accept
import functools

graph = Graph.from_file(sys.argv[1], ignore_errors=True)

initial_partition = GeographicPartition(
    graph,
    assignment="district",
    updaters={
        "cut_edges": cut_edges,
        "population": Tally("p1_001n", alias="population"),
        "public_school_kids": Tally("school_age_public", alias="public_school_kids"),
    },
)

ideal_population = sum(initial_partition["population"].values()) / len(
    initial_partition
)

ideal_public_school_kids = sum(initial_partition["public_school_kids"].values()) / len(
    initial_partition
)

proposal = functools.partial(
    recom, pop_col="p1_001n", pop_target=ideal_population, epsilon=0.02, node_repeats=2
)

compactness_bound = constraints.UpperBound(
    lambda p: len(p["cut_edges"]), 2 * len(initial_partition["cut_edges"])
)
pop_constraint = constraints.within_percent_of_ideal_population(initial_partition, 0.02)


def substantially_similar_kids(partition):
    return (
        1.0
        - max(
            abs(val / ideal_public_school_kids - 1)
            for val in partition["public_school_kids"].values()
        )
    ) ** 2


chain = MarkovChain(
    proposal=proposal,
    constraints=[
        compactness_bound,
        pop_constraint,
    ],
    accept=substantially_similar_kids,
    initial_state=initial_partition,
    total_steps=1000,
)


for partition in chain:
    print(substantially_similar_kids(partition))
