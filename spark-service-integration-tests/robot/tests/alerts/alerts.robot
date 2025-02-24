*** Variables ***
${ALERT_RETRY_TIME}                      5min
${ALERT_RETRY_INTERVAL}                  5s
${NAMESPACE}                             %{NAMESPACE}
${SPARK_CONTROLLER_DEPLOYMENT_NAME}      %{SPARK_CONTROLLER_DEPLOYMENT_NAME}
${SPARK_WEBHOOK_DEPLOYMENT_NAME}         %{SPARK_WEBHOOK_DEPLOYMENT_NAME}

*** Settings ***
Library  MonitoringLibrary  host=%{PROMETHEUS_URL}
Library  PlatformLibrary  managed_by_operator=true
Library  Collections
Library    String
Library  ../lib/jsonObject.py

*** Keywords ***
Check Alert Status
    [Arguments]  ${alert_name}  ${exp_status}
    ${status}=  Get Alert Status  ${alert_name}  ${NAMESPACE}
    Should Be Equal As Strings  ${status}  ${exp_status}

Check That Prometheus Alert Is Active
    [Arguments]  ${alert_name}
    Wait Until Keyword Succeeds  ${ALERT_RETRY_TIME}  ${ALERT_RETRY_INTERVAL}
    ...  Check Alert Status  ${alert_name}  firing

Check That Prometheus Alert Is Inactive
    [Arguments]  ${alert_name}
    Wait Until Keyword Succeeds  ${ALERT_RETRY_TIME}  ${ALERT_RETRY_INTERVAL}
    ...  Check Alert Status  ${alert_name}  inactive

Scale Down Deployment
    [Arguments]  ${deployment_name}
    ${replicas}=  Set Variable  1
    Set Test Variable  ${replicas}
    ${deployment}=  Get Deployment Entity  ${deployment_name}  ${NAMESPACE}
    ${replicas}=  Set Variable  ${deployment.spec.replicas}
    Set Test Variable  ${replicas}
    Set Replicas For Deployment Entity  ${deployment_name}  ${NAMESPACE}  replicas=0

Scale Up Deployment
    [Arguments]  ${deployment_name}
    Set Replicas For Deployment Entity  ${deployment_name}  ${NAMESPACE}  replicas=${replicas}

Scale Down Resources
    [Arguments]  ${deployment_name}
    ${old_resources}=    Get Deployment Resources  ${deployment_name}  ${NAMESPACE}
    Set Test Variable  ${old_resources}
    Patch Deployment Resources  ${deployment_name}  ${NAMESPACE}

Scale Up Resources
    [Arguments]  ${deployment_name}
    Sleep    10s
    Patch Deployment Resources  ${deployment_name}  ${NAMESPACE}    ${old_resources}

*** Test Cases ***
Spark Operator Controller Is Down Alert
    [Tags]  alerts
    ${alert_name}=   Set Variable   SparkOperatorControllerIsDown
    Check That Prometheus Alert Is Inactive  ${alert_name}
    Scale Down Deployment  ${SPARK_CONTROLLER_DEPLOYMENT_NAME}
    Check That Prometheus Alert Is Active  ${alert_name}
    [Teardown]  Run Keywords
                ...  Scale Up Deployment  ${SPARK_CONTROLLER_DEPLOYMENT_NAME}
                ...  AND  Check That Prometheus Alert Is Inactive  ${alert_name}

Spark Operator Controller Is Degraded Alert
    [Tags]  alerts
    ${alert_name}=   Set Variable   SparkOperatorControllerIsDegraded
    Check That Prometheus Alert Is Inactive  ${alert_name}
    Scale Down Resources  ${SPARK_CONTROLLER_DEPLOYMENT_NAME}
    Check That Prometheus Alert Is Active  ${alert_name}
    [Teardown]  Run Keywords
                ...  Scale Up Resources  ${SPARK_CONTROLLER_DEPLOYMENT_NAME}
                ...  AND  Check That Prometheus Alert Is Inactive  ${alert_name}


Spark Operator Webhook Is Down Alert
    [Tags]  alerts
    ${alert_name}=   Set Variable   SparkOperatorWebhookIsDown
    Check That Prometheus Alert Is Inactive  ${alert_name}
    Scale Down Deployment  ${SPARK_WEBHOOK_DEPLOYMENT_NAME}
    Check That Prometheus Alert Is Active  ${alert_name}
    [Teardown]  Run Keywords
                ...  Scale Up Deployment  ${SPARK_WEBHOOK_DEPLOYMENT_NAME}
                ...  AND  Check That Prometheus Alert Is Inactive  ${alert_name}

Spark Operator Webhook Is Degraded Alert
    [Tags]  alerts
    ${alert_name}=   Set Variable   SparkOperatorWebhookIsDegraded
    Check That Prometheus Alert Is Inactive  ${alert_name}
    Scale Down Resources  ${SPARK_WEBHOOK_DEPLOYMENT_NAME}
    Check That Prometheus Alert Is Active  ${alert_name}
    [Teardown]  Run Keywords
                ...  Scale Up Resources  ${SPARK_WEBHOOK_DEPLOYMENT_NAME}
                ...  AND  Check That Prometheus Alert Is Inactive  ${alert_name}




