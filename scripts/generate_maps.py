import functools
import json

import click
import tqdm
from gerrychain import GeographicPartition, Graph, MarkovChain, constraints, accept
from gerrychain.proposals import recom
from gerrychain.updaters import Tally, cut_edges


def max_diff(values, scaling):
    return max(abs(val / scaling - 1) for val in values)


@click.command()
@click.argument("input_geojson")
def main(input_geojson):
    graph = Graph.from_file(input_geojson, ignore_errors=True)

    initial_partition = GeographicPartition(
        graph,
        assignment="district",
        updaters={
            "cut_edges": cut_edges,
            "population": Tally("p1_001n", alias="population"),
            "public_school_kids": Tally(
                "school_age_public", alias="public_school_kids"
            ),
        },
    )

    ideal_population = sum(initial_partition["population"].values()) / len(
        initial_partition
    )

    proposal = functools.partial(
        recom,
        pop_col="p1_001n",
        pop_target=ideal_population,
        epsilon=0.02,
        node_repeats=2,
    )

    compactness_bound = constraints.UpperBound(
        lambda p: len(p["cut_edges"]), 1 * len(initial_partition["cut_edges"])
    )
    pop_constraint = constraints.within_percent_of_ideal_population(
        initial_partition, 0.02
    )

    ideal_public_school_kids = sum(
        initial_partition["public_school_kids"].values()
    ) / len(initial_partition)

    def kid_constraint(partition):
        return max_diff(
            partition["public_school_kids"].values(), ideal_public_school_kids
        ) < 0.5

    chain = MarkovChain(
        proposal=proposal,
        constraints=[compactness_bound, pop_constraint, kid_constraint],
        accept=accept.always_accept,
        initial_state=initial_partition,
        total_steps=1000,
    )

    assignments = {}

    for chain_id, partition in tqdm.tqdm(enumerate(chain)):
        with open(input_geojson) as f:
            blocks = json.load(f)

        for i, feature in enumerate(blocks["features"]):
            block_id = feature['properties']['block_id']
            if block_id in assignments:
                assignments[block_id][chain_id] = partition.assignment[i]
            else:
                assignments[block_id] = {chain_id: partition.assignment[i]}

    click.echo(json.dumps(assignments))

if __name__ == "__main__":
    main()
