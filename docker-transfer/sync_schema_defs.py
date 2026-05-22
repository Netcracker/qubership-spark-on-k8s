import json
from pathlib import Path
from copy import deepcopy

# Shared definitions file
COMMON_DEFS_FILE = Path("commondefs.json")

# Target schema files
SCHEMA_FILES = [
    Path("chart/helm/spark-on-k8s/values.schema.json"),
    Path("chart/helm/spark-on-k8s/charts/spark-history-server/values.schema.json"),
    Path("chart/helm/spark-on-k8s/charts/spark-thrift-server/values.schema.json"),
    Path("chart/helm/spark-on-k8s/charts/spark-integration-tests/values.schema.json"),
    Path("chart/helm/spark-on-k8s/charts/spark-operator/values.schema.json")    
]

with open(COMMON_DEFS_FILE, "r") as f:
    common_defs = json.load(f)

if "definitions" in common_defs:
    definitions_to_copy = common_defs["definitions"]
else:
    definitions_to_copy = common_defs

for schema_path in SCHEMA_FILES:
    print(f"Processing: {schema_path}")

    with open(schema_path, "r") as f:
        schema = json.load(f)

    if "definitions" not in schema:
        schema["definitions"] = {}

    # Copy all definitions
    for key, value in definitions_to_copy.items():
        schema["definitions"][key] = deepcopy(value)
        print(f"  Added/Updated: {key}")

    # Write updated schema
    with open(schema_path, "w") as f:
        json.dump(schema, f, indent=2)

    print(f"Updated: {schema_path}\n")

print("All definitions copied successfully.")