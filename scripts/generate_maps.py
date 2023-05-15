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


def district_subgroup_plurality(partition):
    subgroups = ("black_cvap", "white_cvap", "latino_cvap", "asian_cvap")

    districts = {i: {"subgroup": None, "proportion": 0} for i in range(len(partition))}

    for subgroup in subgroups:
        for district, count in partition[subgroup].items():
            proportion = count / partition["total_cvap"][district]
            if proportion > districts[district]["proportion"]:
                districts[district]["subgroup"] = subgroup
                districts[district]["proportion"] = proportion

    return districts


@click.command()
@click.argument("input_geojson")
@click.options("--n_minority_districts", type=int)
@click.options("--kids_variation", type=float, default=float('inf'))
def main(input_geojson, n_minority_districts, kids_variation):
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

    winning_districts = functools.partial(
        district_winners,
        candidates=(
            "paul vallas",
            'jesus "chuy" garcia',
            "brandon johnson",
            "lori e. lightfoot",
        ),
    )

    def minority_preferred_districts(partition):
        return (
            sum(
                n_districts
                for candidate, n_districts in winning_districts(partition).items()
                if candidate in {'jesus "chuy" garcia', "lori e. lightfoot"}
            )
            >= n_minority_districts
        )

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
        total_steps=10000,
    )

    assignments = {}

    for chain_id, partition in tqdm.tqdm(enumerate(chain)):
        with open(input_geojson) as f:
            blocks = json.load(f)

        for i, feature in enumerate(blocks["features"]):
            block_id = feature["properties"]["precinct_id"]
            if block_id in assignments:
                assignments[block_id][chain_id] = partition.assignment[i]
            else:
                assignments[block_id] = {chain_id: partition.assignment[i]}

    click.echo(json.dumps(assignments))


if __name__ == "__main__":
    main()
