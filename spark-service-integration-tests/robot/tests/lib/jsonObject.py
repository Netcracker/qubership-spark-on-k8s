import yaml
from PlatformLibrary import PlatformLibrary
from kubernetes import client, config

try:
    config.load_incluster_config()
except:
    config.load_kube_config()

rbac_api = client.RbacAuthorizationV1Api()
core_v1 = client.CoreV1Api()
custom_api = client.CustomObjectsApi()


def delete_k8s_secret(name, namespace):
    try:
        core_v1.delete_namespaced_secret(name, namespace)
    except client.exceptions.ApiException as e:
        if e.status != 404:
            raise e


def delete_volcano_queue(name):
    try:
        custom_api.delete_cluster_custom_object(
            group="scheduling.volcano.sh", version="v1beta1", plural="queues", name=name
        )
    except client.exceptions.ApiException as e:
        if e.status != 404:
            raise e


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


def patch_role_secret_access(role_name, namespace, allow=True):

    role = pl_lib.get_role(role_name, namespace)

    secret_rule = {"apiGroups": [""], "resources": ["secrets"], "verbs": ["delete"]}

    if allow:
        if secret_rule not in role.rules:
            role.rules.append(secret_rule)
    else:
        role.rules = [
            rule for rule in role.rules if rule.get("resources") != ["secrets"]
        ]

    pl_lib.patch_namespaced_role(role_name, namespace, role)


def patch_role_resource_access(
    role_name, namespace, resource_type, api_group="", allow=True
):

    role = rbac_api.read_namespaced_role(role_name, namespace)

    if role.rules is None:
        role.rules = []

    rule_obj = client.V1PolicyRule(
        api_groups=[api_group],
        resources=[resource_type],
        verbs=["delete", "get", "list"],
    )

    if allow:
        
        exists = any(resource_type in (r.resources or []) for r in role.rules)
        if not exists:
            role.rules.append(rule_obj)
    else:
        
        role.rules = [r for r in role.rules if resource_type not in (r.resources or [])]

    rbac_api.patch_namespaced_role(role_name, namespace, role)