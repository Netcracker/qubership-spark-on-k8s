from pathlib import Path
import re
import sys

controller_file = Path(
    "./chart/helm/spark-on-k8s/charts/spark-operator/templates/controller/deployment.yaml"
)
webhook_file = Path(
    "./chart/helm/spark-on-k8s/charts/spark-operator/templates/webhook/deployment.yaml"
)


def fail(msg):
    print(f"ERROR: {msg}")
    sys.exit(1)


def success(msg):
    print(f"{msg}")


def get_pattern():
    return (
        r"\{\{\-?\s*with\s+\.Values\.[\w\.]+\.podSecurityContext"
        r"\s*\}\}\s*"
        r"securityContext:\s*"
        r"\{\{\-?\s*toYaml\s+\.\s*\|\s*nindent\s+\d+\s*\}\}\s*"
        r"\{\{\-?\s*end\s*\}\}"
    )


def validate_structure(content, file_path):
    print("Validating structure...")

    # securityContext exists
    if "securityContext:" not in content:
        fail(f"securityContext not found in {file_path}")
    success("securityContext block found")

    # exactly one containers block
    containers = re.findall(r"^\s*containers:\s*$", content, re.MULTILINE)
    if len(containers) != 1:
        fail(
            f"Expected exactly 1 'containers:' block, found {len(containers)} in {file_path}"
        )
    success("Exactly one containers block found")

    # detect initContainers / sidecars
    if re.search(r"^\s*initContainers:\s*$", content, re.MULTILINE):
        fail(f"initContainers detected in {file_path} — review required")
    success("No initContainers detected")


def patch_sc(file_path, sc_var):
    print(f"\n Patching {file_path}...")

    if not file_path.exists():
        fail(f"File not found: {file_path}")

    content = file_path.read_text()
    pattern = get_pattern()

    # PRE-VALIDATION
    validate_structure(content, file_path)

    matches = re.findall(pattern, content)
    if len(matches) == 0:
        fail(f"No matching securityContext block found in {file_path}")
    if len(matches) > 1:
        fail(f"Multiple matching blocks found in {file_path}")

    success("Exactly one matching securityContext block found")

    new_block = f"""securityContext:
        {{{{- $isOpenShift := .Capabilities.APIVersions.Has "security.openshift.io/v1" -}}}}
        {{{{- $omit := default true .Values.securityContext.openShift.omitRunAsUser -}}}}

        {{{{- if and $isOpenShift $omit }}}}
        {{{{ toYaml (omit .Values.{sc_var}.podSecurityContext "runAsUser" "fsGroup" "runAsGroup") | nindent 8 }}}}
        {{{{- else }}}}
        {{{{- toYaml .Values.{sc_var}.podSecurityContext | nindent 8 }}}}
        {{{{- end }}}}"""

    new_content, count = re.subn(pattern, new_block, content)

    # POST-VALIDATION
    if count != 1:
        fail(f"Expected exactly 1 replacement, got {count} in {file_path}")
    success("Exactly one block replaced")

    if new_content == content:
        fail(f"Patch did not change anything in {file_path}")
    success("Content successfully modified")

    file_path.write_text(new_content)
    success(f"Successfully patched {file_path.name}")


if __name__ == "__main__":
    patch_sc(controller_file, "controller")
    patch_sc(webhook_file, "webhook")
