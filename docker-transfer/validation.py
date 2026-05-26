import json
import yaml
import sys


def validate_defaults(values, default_values_schema, param_path=""):
    # Handle dict
    if isinstance(values, dict):
        for key, value in values.items():
            if key in default_values_schema.get("properties", {}):
                schema_prop = default_values_schema["properties"][key]

                if "default" in schema_prop and not isinstance(value, (dict, list)):
                    default_val = schema_prop.get("default", "")
                    if (
                        isinstance(default_val, str)
                        and default_val.startswith("see ")
                        and default_val.endswith(" values.yaml file")
                    ):
                        print(
                            f"Skipping validation for this parameter: {param_path}{key}."
                        )
                        continue
                    if schema_prop["default"] != value:
                        print(
                            f"form schema: {schema_prop["default"]}, from values: {value}"
                        )
                        raise ValueError(f"{param_path}{key} is different!")
                else:
                    validate_defaults(
                        value,
                        schema_prop,
                        f"{param_path}{key}.",
                    )

    # Handle list
    elif isinstance(values, list):
        item_schema = default_values_schema.get("items", {})

        for i, item in enumerate(values):
            validate_defaults(
                item,
                item_schema,
                f"{param_path}[{i}].",
            )


def load_yaml(file_path):
    with open(file_path, "r") as f:
        return yaml.safe_load(f)


def load_json(file_path):
    with open(file_path, "r") as f:
        return json.load(f)


def run_validation(values_file, schema_file):
    values = load_yaml(values_file)
    schema = load_json(schema_file)
    print(f"validation started for: {schema_file} ")
    validate_defaults(values, schema)

    print(f"Validation passed for: {schema_file}!")


if __name__ == "__main__":
    values_file = sys.argv[1]
    schema_file = sys.argv[2]

    run_validation(values_file, schema_file)
