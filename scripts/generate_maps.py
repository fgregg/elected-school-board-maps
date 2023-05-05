import functools
import json
import math

import click
import tqdm
from gerrychain import GeographicPartition, Graph, MarkovChain, constraints, accept
from gerrychain.proposals import recom
from gerrychain.updaters import Tally, cut_edges


def std(values, scaling):
    return math.sqrt(sum((val - scaling) ** 2 for val in values)) / len(values)


def max_diff(values, scaling):
    return max(abs(val / scaling - 1) for val in values)


@click.command()
@click.option("--n_epochs", type=int, default=10)
@click.option("--n_mutations", type=int, default=10)
@click.option("--n_seeds", type=int, default=5)
@click.option("--n_steps", type=int, default=20)
@click.argument("input_geojson")
def main(input_geojson, n_epochs, n_mutations, n_seeds, n_steps):
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
        lambda p: len(p["cut_edges"]), 2 * len(initial_partition["cut_edges"])
    )
    pop_constraint = constraints.within_percent_of_ideal_population(
        initial_partition, 0.02
    )

    ideal_public_school_kids = sum(
        initial_partition["public_school_kids"].values()
    ) / len(initial_partition)

    def sort_key(partition):
        return max_diff(
            partition["public_school_kids"].values(), ideal_public_school_kids
        )

    seeds = [initial_partition]

    for epoch in tqdm.trange(n_epochs, desc="    epoch", position=0):
        children = []
        for seed in tqdm.tqdm(seeds, desc="     seed", leave=False, position=1):
            for _ in tqdm.trange(
                n_mutations, desc=" mutation", leave=False, position=2
            ):
                chain = MarkovChain(
                    proposal=proposal,
                    constraints=[compactness_bound, pop_constraint],
                    accept=accept.always_accept,
                    initial_state=seed,
                    total_steps=n_steps,
                )

                children.extend([partition for partition in chain])

        seeds = sorted(children, key=sort_key)[:n_seeds]
        click.echo([sort_key(partition) for partition in seeds], err=True)

        best_partition = seeds[0]
        with open(input_geojson) as f:
            blocks = json.load(f)

        for i, feature in enumerate(blocks["features"]):
            feature["properties"]["district"] = best_partition.assignment[i]

        with open(f"epoch_{epoch}.geojson", "w") as f:
            json.dump(blocks, f)


if __name__ == "__main__":
    main()
