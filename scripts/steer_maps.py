import functools
import json
import random

import click
import tqdm
from gerrychain import GeographicPartition, Graph, MarkovChain, accept, constraints
from gerrychain.proposals import recom
from gerrychain.updaters import Election, Tally, cut_edges


def max_diff(values, scaling):
    return max(abs(val / scaling - 1) for val in values)


@click.command()
@click.option("--n_epochs", type=int, default=10)
@click.option("--n_mutations", type=int, default=10)
@click.option("--n_seeds", type=int, default=5)
@click.option("--n_steps", type=int, default=20)
@click.option("--steer_kids", is_flag=True, default=False)
@click.argument("input_geojson")
def main(input_geojson, n_epochs, n_mutations, n_seeds, n_steps, steer_kids):
    election = Election(
        "2023 General",
        {
            'jesus "chuy" garcia': 'jesus "chuy" garcia',
            "lori e. lightfoot": "lori e. lightfoot",
            "brandon johnson": "brandon johnson",
            "paul vallas": "paul vallas",
        },
    )

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
            "2023 General": election,
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
        initial_partition, 0.03
    )

    ideal_public_school_kids = sum(
        initial_partition["public_school_kids"].values()
    ) / len(initial_partition)

    def minority_preferred_districts(partition):
        return partition["2023 General"].wins('jesus "chuy" garcia') + partition[
            "2023 General"
        ].wins("lori e. lightfoot")

    if steer_kids:

        def sort_key(partition):
            max_diff_kids = max_diff(
                partition["public_school_kids"].values(), ideal_public_school_kids
            )

            return (
                minority_preferred_districts(partition),
                -max_diff_kids,
                random.random(),
            )

    else:

        def sort_key(partition):
            return minority_preferred_districts(partition), random.random()

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

        seeds = sorted(children, key=sort_key, reverse=True)[:n_seeds]
        for partition in seeds:
            click.echo(winning_districts(partition), err=True)
            click.echo(sort_key(partition), err=True)

        click.echo(
            [minority_preferred_districts(partition) for partition in seeds], err=True
        )

        best_partition = seeds[0]
        with open(input_geojson) as f:
            blocks = json.load(f)

        for i, feature in enumerate(blocks["features"]):
            feature["properties"]["district"] = best_partition.assignment[i]

        with open(f"epoch_{epoch}.geojson", "w") as f:
            json.dump(blocks, f)


if __name__ == "__main__":
    main()
