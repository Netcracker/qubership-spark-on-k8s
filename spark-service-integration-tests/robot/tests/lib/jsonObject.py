import yaml
from PlatformLibrary import PlatformLibrary


def parse_yaml_from_file(file_path):
    return yaml.safe_load(open(file_path))


def check_existence_and_status_of_pod(pod_name, body, state="Running"):
    for pod in body:
        if pod_name in pod.metadata.name and pod.status.phase == state:
            return True
        else:
            return False


def update_app_yaml(
    app_image,
    path_to_app="../test-app/spark-pi.yml",
    sa_name="sparkoperator-spark",
    s3_path="",
    s3_a_key="",
    s3_s_key="",
    arguments="50",
    use_volcano=False,
):
    stream = open(path_to_app, "r")
    data = yaml.safe_load(stream)
    data["spec"]["image"] = app_image
    if "initContainers" in data["spec"]["driver"]:
        data["spec"]["driver"]["initContainers"][0]["image"] = app_image
    data["metadata"]["name"] = data["metadata"]["name"] + "-integration-tests"
    data["spec"]["driver"]["serviceAccount"] = sa_name
    if use_volcano:
        data["spec"]["batchScheduler"] = "volcano"
        data["spec"]["batchSchedulerOptions"] = {
            "queue": "sparkqueue",
            "resources": {"cpu": "3", "memory": "3G"},
        }
    if "arguments" in data["spec"]:
        data["spec"]["arguments"] = [arguments]
    if "hadoopConf" in data["spec"]:
        if "fs.s3a.endpoint" in data["spec"]["hadoopConf"]:
            data["spec"]["hadoopConf"]["fs.s3a.endpoint"] = s3_path
            data["spec"]["hadoopConf"]["fs.s3a.access.key"] = s3_a_key
            data["spec"]["hadoopConf"]["fs.s3a.secret.key"] = s3_s_key
    return data


reduced_resources = dict(
    requests=dict(cpu="1m", memory="1Mi"), limits=dict(cpu="1m", memory="1Mi")
)

pl_lib = PlatformLibrary(managed_by_operator="true")


def get_deployment_resources(name, namespace):
    deployment = pl_lib.get_deployment_entity(name, namespace)
    resources = deployment.spec.template.spec.containers[0].resources
    requests_cpu = resources.requests.get("cpu")
    requests_memory = resources.requests.get("memory")
    limits_cpu = resources.limits.get("cpu")
    limits_memory = resources.limits.get("memory")
    resources_dict = dict(
        requests=dict(cpu=requests_cpu, memory=requests_memory),
        limits=dict(cpu=limits_cpu, memory=limits_memory),
    )
    return resources_dict


def patch_deployment_resources(name, namespace, resources_dict=reduced_resources):
    deployment = pl_lib.get_deployment_entity(name, namespace)
    deployment.spec.template.spec.containers[0].resources = resources_dict
    pl_lib.patch_namespaced_deployment_entity(name, namespace, deployment)


def check_volcano_pending_status(app_name, namespace):
    pod_name = f"{app_name}-driver"
    try:
        pod = pl_lib.get_pod(pod_name, namespace)
        if not pod.status or not pod.status.conditions:
            return False

        for condition in pod.status.conditions:
            if condition.type == "PodScheduled" and condition.status == "False":
                if (
                    condition.reason == "Unschedulable"
                    and "pod group is not ready" in condition.message
                ):
                    return True
        return False
    except Exception:
        return False
