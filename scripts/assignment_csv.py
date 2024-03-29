import csv
import json
import sys

assignments = json.load(sys.stdin)

writer = csv.DictWriter(
    sys.stdout,
    fieldnames=["block"] + [str(i) for i in range(10000) if i % 10 == 0],
    extrasaction="ignore",
)

writer.writeheader()

for block_id, partitions in assignments.items():
    partitions["block"] = block_id
    writer.writerow(partitions)
