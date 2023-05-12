import functools
import json

import click
import tqdm
from gerrychain import GeographicPartition, Graph, MarkovChain, constraints, accept
from gerrychain.proposals import recom
from gerrychain.updaters import Tally, cut_edges


def max_diff(values, scaling):
    return max(abs(val / scaling - 1) for val in values)


def district_winners(partition, candidates):
    districts = {i: {"candidate": None, "votes": 0} for i in range(len(partition))}

    for candidate in candidates:
        for district, votes in partition[candidate].items():
            if votes > districts[district]["votes"]:
                districts[district]["candidate"] = candidate
                districts[district]["votes"] = votes

    candidate_districts = {candidate: 0 for candidate in candidates}

    for district, winner in districts.items():
        candidate_districts[winner["candidate"]] += 1

    return candidate_districts


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
            # "public_school_kids": Tally(
            #    "school_age_public", alias="public_school_kids"
            # ),
            'jesus "chuy" garcia': Tally('jesus "chuy" garcia'),
            "lori e. lightfoot": Tally("lori e. lightfoot"),
            "brandon johnson": Tally("brandon johnson"),
            "paul vallas": Tally("paul vallas"),
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

    # ideal_public_school_kids = sum(
    #    initial_partition["public_school_kids"].values()
    # ) / len(initial_partition)

    def kid_constraint(partition):
        return (
            max_diff(partition["public_school_kids"].values(), ideal_public_school_kids)
            < 0.5
        )

    winning_districts = functools.partial(
        district_winners,
        candidates=(
            "paul vallas",
            'jesus "chuy" garcia',
            "brandon johnson",
            'lori e. lightfoot',
        ),
    )

    def minority_preferred_districts(partition):
        return sum(
            n_districts
            for candidate, n_districts in winning_districts(partition).items()
            if candidate in {'jesus "chuy" garcia', "lori e. lightfoot"}
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
                    constraints=[
                        compactness_bound,
                        pop_constraint,
                    ],  # , kid_constraint],
                    accept=accept.always_accept,
                    initial_state=seed,
                    total_steps=n_steps,
                )

                children.extend([partition for partition in chain])

        seeds = sorted(children, key=minority_preferred_districts, reverse=True)[
            :n_seeds
        ]
        for partition in seeds:
            winners = winning_districts(partition)
            click.echo(winners, err=True)

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
