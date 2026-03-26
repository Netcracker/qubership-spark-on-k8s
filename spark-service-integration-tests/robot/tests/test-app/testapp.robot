*** Variables ***
${SPARK_APPS_NAMESPACE}       %{SPARK_APPS_NAMESPACE}
${SPARK_APPS_SERVICEACCOUNT}  %{SPARK_APPS_SERVICEACCOUNT}
${BASE_APP_IMAGE}             %{BASE_APP_IMAGE}
${BASE_PY_APP_IMAGE}          %{BASE_PY_APP_IMAGE}
${SPARK_HIVE_IMAGE}           %{SPARK_HIVE_IMAGE}
${S3_ENDPOINT}                %{S3_ENDPOINT}
${S3_ACCESS_KEY}              %{S3_ACCESS_KEY}
${S3_SECRET_KEY}              %{S3_SECRET_KEY}
${SPARK_HIVE_INTEGRATION_TESTS_ENABLED}  %{SPARK_HIVE_INTEGRATION_TESTS_ENABLED}
${VOLCANO_INTEGRATION_TESTS_ENABLED}     %{VOLCANO_INTEGRATION_TESTS_ENABLED}
${MANAGED_BY_OPERATOR}        true
${PLURAL}                     sparkapplications
${GROUP}                      sparkoperator.k8s.io
${VERSION}                    v1beta2
${KIND}                       SparkApplication
${COUNT_OF_RETRY}             160x
${RETRY_INTERVAL}             5s


*** Settings ***
Library  String
Library  Collections
Library  RequestsLibrary
Library  OperatingSystem
Library  PlatformLibrary  managed_by_operator=${MANAGED_BY_OPERATOR}
Library  ../lib/jsonObject.py


*** Keywords ***
Create CR For Spark Application
    [Arguments]  ${APP_IMAGE}  ${PATH_TO_APP}  ${VOLCANO}=False
    ${body}=    Update App Yaml  ${APP_IMAGE}  ${PATH_TO_APP}  ${SPARK_APPS_SERVICEACCOUNT}  ${S3_ENDPOINT}  ${S3_ACCESS_KEY}  ${S3_SECRET_KEY}  ${VOLCANO}
    Create Namespaced Custom Object  ${GROUP}  ${VERSION}  ${SPARK_APPS_NAMESPACE}  ${PLURAL}  ${body}
    Log To Console  \nSpark App is created!

Get CR In Namespace
    ${custom_resource} =  Get Custom Resource  ${GROUP}/${VERSION}  ${KIND}  ${SPARK_APPS_NAMESPACE}  ${APP_NAME}
    Log To Console  ${custom_resource}
    RETURN  ${custom_resource}

Delete CR
    [Arguments]  ${APP_NAME}
    Delete Namespaced Custom Object  ${GROUP}  ${VERSION}  ${SPARK_APPS_NAMESPACE}  ${PLURAL}  ${APP_NAME}

Check Status Of Pod For App
    [Arguments]  ${pod_name}  ${state}
    ${body} =  Get Pods  ${SPARK_APPS_NAMESPACE}
    ${resp} =  Check Existence And Status Of Pod  ${pod_name}  ${body}  ${state}
    Should Be True  ${resp}

Safe Delete Secret
    [Arguments]    ${SECRET_NAME}    ${NAMESPACE}=${SPARK_APPS_NAMESPACE}
    Run Keyword And Ignore Error    Delete K8s Secret    ${SECRET_NAME}    ${NAMESPACE}

Safe Delete Queue
    [Arguments]    ${QUEUE_NAME}
    Run Keyword And Ignore Error    Delete Volcano Queue    ${QUEUE_NAME}

Check Status CR
    [Arguments]  ${APP_NAME}  ${status}
    ${cr_body} =  Get Namespaced Custom Object Status  ${GROUP}  ${VERSION}  ${SPARK_APPS_NAMESPACE}  ${PLURAL}  ${APP_NAME}
    Should Contain  str(${cr_body})  ${status}

Verify Volcano Is Managing The Queue
    [Arguments]    ${APP1}    ${APP2}
    ${status1}=    Run Keyword And Return Status    Check Volcano Pending Status    ${APP1}    ${SPARK_APPS_NAMESPACE}
    ${status2}=    Run Keyword And Return Status    Check Volcano Pending Status    ${APP2}    ${SPARK_APPS_NAMESPACE}
    Should Be True    ${status1} or ${status2}
    Log To Console    \nSUCCESS: Volcano is actively managing the resource queue!

*** Test Cases ***
Run Spark to Hive Connection Application
    [Tags]  hive-connection  test_app
    Skip If    '${SPARK_HIVE_INTEGRATION_TESTS_ENABLED}' == 'false'    Skipping Hive integration tests since it is disabled.
    [Teardown]  Run Keywords   Delete CR  spark-hive-test-integration-tests
    ...    AND    Safe Delete Secret    s3-secrets
    Create CR For Spark Application  ${SPARK_HIVE_IMAGE}  tests/test-app/spark-hive-connection-app.yaml
    Wait Until Keyword Succeeds  ${COUNT_OF_RETRY}  ${RETRY_INTERVAL}
    ...  Check Status CR  spark-hive-test-integration-tests  RUNNING
    Log To Console  Spark to Hive connection application is running
    Wait Until Keyword Succeeds  ${COUNT_OF_RETRY}  ${RETRY_INTERVAL}
    ...  Check Status CR  spark-hive-test-integration-tests  COMPLETED

    Log To Console  Spark to Hive connection application is completed

Run Dual Volcano Scheduled Applications
    [Tags]    volcano    dual_test
    Skip If    '${VOLCANO_INTEGRATION_TESTS_ENABLED}' == 'false'    Skipping Volcano tests.
    [Teardown]    Run Keywords    Delete CR    spark-pi-integration-tests
    ...    AND    Delete CR    spark-pi-long-run-integration-tests
    ...    AND    Safe Delete Queue    sparkqueue

    Create CR For Spark Application    ${BASE_PY_APP_IMAGE}    tests/test-app/spark-pi.yaml    VOLCANO=True
    Create CR For Spark Application    ${BASE_PY_APP_IMAGE}    tests/test-app/spark-pi-long-run.yaml    VOLCANO=True
    Log To Console    \nBoth applications submitted to the Volcano queue.

    
    Wait Until Keyword Succeeds    15x    3s
    ...    Verify Volcano Is Managing The Queue    spark-pi-integration-tests    spark-pi-long-run-integration-tests
    Log To Console    Volcano has successfully scheduled one application and is managing the queue!
    
    Wait Until Keyword Succeeds  ${COUNT_OF_RETRY}  ${RETRY_INTERVAL}
    ...  Check Status CR  spark-pi-integration-tests  RUNNING
    Log To Console   spark-pi-integration-tests is running

    Wait Until Keyword Succeeds  ${COUNT_OF_RETRY}  ${RETRY_INTERVAL}
    ...  Check Status CR  spark-pi-long-run-integration-tests  RUNNING
    Log To Console   spark-pi-long-run-integration-tests is running

    Wait Until Keyword Succeeds  ${COUNT_OF_RETRY}  ${RETRY_INTERVAL}
    ...  Check Status CR  spark-pi-integration-tests  COMPLETED

    Wait Until Keyword Succeeds  ${COUNT_OF_RETRY}  ${RETRY_INTERVAL}
    ...  Check Status CR  spark-pi-long-run-integration-tests  COMPLETED

    Log To Console  Volcano test is completed

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
