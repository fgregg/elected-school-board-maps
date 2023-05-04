import functools
import json
import math
import random
import sys

import click
from gerrychain import GeographicPartition, Graph, MarkovChain, constraints
from gerrychain.proposals import recom
from gerrychain.updaters import Tally, cut_edges


def std(values, scaling):
    return math.sqrt(sum((val / scaling - 1) ** 2 for val in values)) / len(values)


def max_diff(values, scaling):
    return max(abs(val / scaling - 1) for val in values)


def substantially_similar_kids(ideal_public_school_kids):
    previous_max = float("inf")
    previous_sd = float("inf")

    def smaller_differences(partition):
        nonlocal previous_max
        nonlocal previous_sd
        current = max_diff(
            partition["public_school_kids"].values(), ideal_public_school_kids
        )
        sd = max_diff(
            partition["public_school_kids"].values(), ideal_public_school_kids
        )

        if current < previous_max or (current == previous_max and sd < previous_sd):
            previous_max = current
            previous_sd = sd
            return 1.0

        elif random.random() < 0.20:
            previous_max = current
            previous_sd = sd
            return 1.0

        else:
            return 0.0

    return smaller_differences


@click.command()
@click.argument("input_geojson")
@click.option("-s", "--steer", is_flag=True, default=False)
@click.option("-c", "--constraint", type=float, default=float("inf"))
@click.option("-e", "--early", type=float, default=0.0)
def main(input_geojson, steer, constraint, early):
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

    kid_constraint = (
        lambda partition: max_diff(
            partition["public_school_kids"], ideal_public_school_kids
        )
        < constraint
    )

    if steer:
        accept = substantially_similar_kids(ideal_public_school_kids)
    else:
        accept = lambda partition: 1.0

    chain = MarkovChain(
        proposal=proposal,
        constraints=[
            compactness_bound,
            pop_constraint,
            kid_constraint,
        ],
        accept=accept,
        initial_state=initial_partition,
        total_steps=1000,
    )

    for partition in chain:
        click.echo(
            std(partition["public_school_kids"].values(), ideal_public_school_kids),
            err=True,
        )
        diff = max_diff(
            partition["public_school_kids"].values(), ideal_public_school_kids
        )

        click.echo(diff, err=True)
        click.echo(
            {k: int(v) for k, v in sorted(partition["public_school_kids"].items())},
            err=True,
        )
        if diff < early:
            with open(sys.argv[1]) as f:
                blocks = json.load(f)
            for i, feature in enumerate(blocks["features"]):
                feature["properties"]["district"] = partition.assignment[i]

            click.echo(json.dumps(blocks))
            break


if __name__ == "__main__":
    main()
