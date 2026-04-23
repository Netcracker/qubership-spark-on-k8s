from pathlib import Path
import re

controller_file = Path("./chart/helm/spark-on-k8s/charts/spark-operator/templates/controller/deployment.yaml")
webhook_file = Path("./chart/helm/spark-on-k8s/charts/spark-operator/templates/webhook/deployment.yaml")


def patch_sc(file_path, sc_var):
    print(f"Patching {file_path} for {sc_var}...")
    file_path = Path(file_path)

    if not file_path.exists():
        print(f"File not found: {file_path}")
        return

    content = file_path.read_text()

    def get_pattern():
       return (
        r'\{\{\-?\s*with\s+\.Values\.[\w\.]+\.podSecurityContext'
        r'\s*\}\}\s*'
        r'securityContext:\s*'
        r'\{\{\-?\s*toYaml\s+\.\s*\|\s*nindent\s+\d+\s*\}\}\s*'
        r'\{\{\-?\s*end\s*\}\}'
       )

    
    new_block = f"""securityContext:
        {{{{- if eq (default "KUBERNETES" .Values.PAAS_PLATFORM) "OPENSHIFT" }}}}
        {{{{ toYaml (omit .Values.{sc_var}.podSecurityContext "runAsUser" "fsGroup" "runAsGroup") | nindent 8 }}}}
        {{{{- else }}}}
        {{{{- toYaml .Values.{sc_var}.podSecurityContext  | nindent 8 }}}}
        {{{{- end }}}}"""
    
    new_content = re.sub(get_pattern(), new_block, content)

    if new_content != content:
        file_path.write_text(new_content)
        print(f"Successfully patched {file_path.name}")

if __name__ == "__main__":
     patch_sc(controller_file, "controller")
     patch_sc(webhook_file, "webhook")