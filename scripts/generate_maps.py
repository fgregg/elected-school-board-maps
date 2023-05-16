import functools
import json

import click
import tqdm
from gerrychain import GeographicPartition, Graph, MarkovChain, accept, constraints
from gerrychain.proposals import recom
from gerrychain.updaters import Election, Tally, cut_edges


def max_diff(values, scaling):
    return max(abs(val / scaling - 1) for val in values)


@click.command()
@click.argument("input_geojson")
@click.option("--n_minority_districts", type=int)
@click.option("--kids_variation", type=float, default=float("inf"))
@click.option("--chain_length", type=int, default=10000)
def main(input_geojson, n_minority_districts, kids_variation, chain_length):
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
        lambda p: len(p["cut_edges"]), 1 * len(initial_partition["cut_edges"])
    )
    pop_constraint = constraints.within_percent_of_ideal_population(
        initial_partition, 0.03
    )

    ideal_public_school_kids = sum(
        initial_partition["public_school_kids"].values()
    ) / len(initial_partition)

    def kid_constraint(partition):
        return (
            max_diff(partition["public_school_kids"].values(), ideal_public_school_kids)
            < kids_variation
        )

    def minority_preferred_districts(partition):
        return (
            partition["2023 General"].wins('jesus "chuy" garcia')
            + partition["2023 General"].wins("lori e. lightfoot")
        ) >= n_minority_districts

    chain = MarkovChain(
        proposal=proposal,
        constraints=[
            compactness_bound,
            pop_constraint,
            kid_constraint,
            minority_preferred_districts,
        ],
        accept=accept.always_accept,
        initial_state=initial_partition,
        total_steps=chain_length,
    )

    assignments = {}
    kept_plans = 0

    for chain_id, partition in tqdm.tqdm(enumerate(chain), total=chain_length):
        with open(input_geojson) as f:
            blocks = json.load(f)

        keep = False
        minority_districts = partition["2023 General"].wins(
            'jesus "chuy" garcia'
        ) + partition["2023 General"].wins("lori e. lightfoot")
        if minority_districts > n_minority_districts:
            keep = True

        for i, feature in enumerate(blocks["features"]):
            block_id = feature["properties"]["precinct_id"]
            district_assignment = partition.assignment[i]
            if block_id in assignments:
                assignments[block_id][chain_id] = district_assignment
            else:
                assignments[block_id] = {chain_id: district_assignment}

            if keep:
                feature["properties"]["district"] = district_assignment

        if keep:
            kept_plans += 1
            with open(f"kept_{kept_plans}_{minority_districts}.geojson", "w") as f:
                json.dump(blocks, f)
            break

    click.echo(json.dumps(assignments))


if __name__ == "__main__":
    main()
