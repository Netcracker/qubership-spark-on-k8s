from pathlib import Path
import sys
from ruamel.yaml import YAML
from ruamel.yaml.scalarstring import LiteralScalarString

yaml = YAML()
yaml.preserve_quotes = True


controller_file = Path(
    "./chart/helm/spark-on-k8s/charts/spark-operator/templates/controller/deployment.yaml"
)
webhook_file = Path(
    "./chart/helm/spark-on-k8s/charts/spark-operator/templates/webhook/deployment.yaml"
)


def fail(msg):
    print(f"ERROR: {msg}")
    sys.exit(1)


def build_helm_block(sc_var):
    return LiteralScalarString(f"""{{{{- $isOpenShift := .Capabilities.APIVersions.Has "security.openshift.io/v1" -}}}}
{{{{- $omit := default true .Values.openShift.omit -}}}}        
{{{{- if and $isOpenShift $omit }}}}                                       
{{{{ toYaml (omit .Values.{sc_var}.podSecurityContext "runAsUser" "fsGroup" "runAsGroup") | nindent 8 }}}}
{{{{- else }}}}
{{{{- toYaml .Values.{sc_var}.podSecurityContext | nindent 8 }}}}
{{{{- end }}}}""")


def patch_file(file_path, sc_var):
    print(f"Patching {file_path}...")

    if not file_path.exists():
        fail(f"File not found: {file_path}")

    content = file_path.read_text()

    try:
        data = yaml.load(content)
    except Exception as e:
        fail(f"YAML parsing failed for {file_path}: {e}")

    try:
        spec = data["spec"]["template"]["spec"]
    except KeyError:
        fail(f"Invalid structure in {file_path}: missing spec.template.spec")

    containers = spec.get("containers")
    if not containers:
        fail(f"No containers found in {file_path}")

    if len(containers) != 1:
        fail(f"Expected 1 container, found {len(containers)} in {file_path}")

    if "securityContext" not in spec:
        fail(f"securityContext not found in {file_path}")

    spec["securityContext"] = build_helm_block(sc_var)

    with file_path.open("w") as f:
        yaml.dump(data, f)

    print(f"Successfully patched {file_path.name}")


if __name__ == "__main__":
    patch_file(controller_file, "controller")
    patch_file(webhook_file, "webhook")