*** Variables ***
${SPARK_APPS_NAMESPACE}       %{SPARK_APPS_NAMESPACE}
${SPARK_APPS_SERVICEACCOUNT}  %{SPARK_APPS_SERVICEACCOUNT}
${BASE_APP_IMAGE}             %{BASE_APP_IMAGE}
${BASE_PY_APP_IMAGE}          %{BASE_PY_APP_IMAGE}
${S3_ENDPOINT}                %{S3_ENDPOINT}
${S3_ACCESS_KEY}              %{S3_ACCESS_KEY}
${S3_SECRET_KEY}              %{S3_SECRET_KEY}
${MANAGED_BY_OPERATOR}        true
${PLURAL}                     sparkapplications
${GROUP}                      sparkoperator.k8s.io
${VERSION}                    v1beta2
${KIND}                       SparkApplication
${COUNT_OF_RETRY}             160x
${RETRY_INTERVAL}             5s


*** Settings ***
Library  String
Library	 Collections
Library	 RequestsLibrary
Library  OperatingSystem
Library  PlatformLibrary  managed_by_operator=${MANAGED_BY_OPERATOR}
Library  ../lib/jsonObject.py


*** Keywords ***
Create CR For Spark Application
    [Arguments]  ${APP_IMAGE}  ${PATH_TO_APP}
    ${body}=    Update App Yaml  ${APP_IMAGE}  ${PATH_TO_APP}  ${SPARK_APPS_SERVICEACCOUNT}  ${S3_ENDPOINT}  ${S3_ACCESS_KEY}  ${S3_SECRET_KEY}
    Create Namespaced Custom Object  ${GROUP}  ${VERSION}  ${SPARK_APPS_NAMESPACE}  ${PLURAL}  ${body}
    Log To Console  \nSpark App is created!

Get CR In Namespace
    ${custom_resource} =  Get Custom Resource  ${GROUP}/${VERSION}  ${KIND}  ${SPARK_APPS_NAMESPACE}  ${APP_NAME}
    Log To Console  ${custom_resource}
    [Return]  ${custom_resource}

Delete CR
    [Arguments]  ${APP_NAME}
    Delete Namespaced Custom Object  ${GROUP}  ${VERSION}  ${SPARK_APPS_NAMESPACE}  ${PLURAL}  ${APP_NAME}

Check Status Of Pod For App
    [Arguments]  ${pod_name}  ${state}
    ${body} =  Get Pods  ${SPARK_APPS_NAMESPACE}
    ${resp} =  Check Existence And Status Of Pod  ${pod_name}  ${body}  ${state}
    Should Be True  ${resp}

Check Status CR
    [Arguments]  ${APP_NAME}  ${status}
    ${cr_body} =  Get Namespaced Custom Object Status  ${GROUP}  ${VERSION}  ${SPARK_APPS_NAMESPACE}  ${PLURAL}  ${APP_NAME}
    Should Contain  str(${cr_body})  ${status}

*** Test Cases ***
Run JAVA Spark Application
    [Tags]  java  test_app
    [Teardown]  Delete CR  spark-pi-integration-tests
    Sleep    100 seconds
    Create CR For Spark Application  ${BASE_APP_IMAGE}  tests/test-app/spark-pi.yaml
    Wait Until Keyword Succeeds  ${COUNT_OF_RETRY}  ${RETRY_INTERVAL}
    ...  Check Status CR  spark-pi-integration-tests  RUNNING
    Log To Console  JAVA application is running
    Wait Until Keyword Succeeds  ${COUNT_OF_RETRY}  ${RETRY_INTERVAL}
    ...  Check Status CR  spark-pi-integration-tests  COMPLETED
    Log To Console  JAVA application is completed

Run PYTHON Spark Application
    [Tags]  py  test_app
    [Teardown]  Delete CR  pyspark-pi-integration-tests
    Create CR For Spark Application  ${BASE_PY_APP_IMAGE}  tests/test-app/spark-py-pi.yaml
    Wait Until Keyword Succeeds  ${COUNT_OF_RETRY}  ${RETRY_INTERVAL}
    ...  Check Status CR  pyspark-pi-integration-tests  RUNNING
    Log To Console  PYTHON application is running
    Wait Until Keyword Succeeds  ${COUNT_OF_RETRY}  ${RETRY_INTERVAL}
    ...  Check Status CR  pyspark-pi-integration-tests  COMPLETED
    Log To Console  PYTHON application is completed

Run Long-pi Spark Application
    [Tags]  long-pi  test_app
    [Teardown]  Delete CR  spark-pi-long-run-integration-tests
    Create CR For Spark Application  ${BASE_APP_IMAGE}  tests/test-app/spark-pi-long-run.yaml
    Wait Until Keyword Succeeds  ${COUNT_OF_RETRY}  ${RETRY_INTERVAL}
    ...  Check Status CR  spark-pi-long-run-integration-tests  RUNNING
    Log To Console  Long-pi application is running
    Wait Until Keyword Succeeds  ${COUNT_OF_RETRY}  ${RETRY_INTERVAL}
    ...  Check Status CR  spark-pi-long-run-integration-tests  COMPLETED
    Log To Console  Long-pi application is completed

Run History-Server Spark Application
    [Tags]  history-server  test_app
    [Teardown]  Delete CR  spark-pi-event-logs-s3-integration-tests
    Create CR For Spark Application  ${BASE_APP_IMAGE}  tests/test-app/spark-pi-event-logs-s3.yaml
    Wait Until Keyword Succeeds  ${COUNT_OF_RETRY}  ${RETRY_INTERVAL}
    ...  Check Status CR  spark-pi-event-logs-s3-integration-tests  RUNNING
    Log To Console  History server application is running
    Wait Until Keyword Succeeds  ${COUNT_OF_RETRY}  ${RETRY_INTERVAL}
    ...  Check Status CR  spark-pi-event-logs-s3-integration-tests  COMPLETED
    Log To Console  History server application is completed