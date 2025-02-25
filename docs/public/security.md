## Access to Kuber API

Kubeflow Spark-operator requires extensive access to Kuber API in order to watch/modify CRs and manage spark-application pods.

## Exposed Ports

List of ports used by Spark are as follows: 

| Port | Service                       | Description                                                                                                                                                                                                                                                                                |
|------|-------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 4040 | Spark-thrift server, applications| Spark UI port on applications and thrift-server.                                                                                                                                                                                                                                         |
| 9443 | spark-operator | Specifies webhook port |
| 6060 | spark-operator | Specifies pprof port |
| 8080 | spark-operator | Metrics port |
| 4180 | Oauth2 Proxy | Default container port value if the httpScheme set to http |
| 4443 | Oauth2 Proxy | Default container port value if the httpScheme set to htts |
| 44180 | Oauth2 Proxy | Port to collect prometheus metrics. Disabled by default |
| 18080 | Spark History Server | The Spark History Server service internal port |
| 443 | Spark History Server | External TLS port |
| 6044 | Spark History Server | Internal TLS port |

## Secure Protocols

It is possible to enable TLS in Spark History Server. This process is described in the respective [Spark Operator Installation Procedure](/docs/public/installation.md#spark-history-server-deployment).

## User and Session Management

Local users are not used in Spark Operator and Spark History Server. User and session management are not applicable for these services.

## Audit Event Logs

List of event logs: 

| Priority | Service | Event                       | Example                                                                                                                                                                                                                                                                                |
|------|-------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|
| High | Oauth2 Proxy | Login                         | 10.127.132.216:35528 - d99c946d160dc405026679d4e220a9cd - spark@qubership.com [2024/12/06 04:50:41] [AuthSuccess] Authenticated via OAuth2: Session{email:spark@qubership.com user:2affc30b-a549-4f91-bdbb-025afa2e9d03 PreferredUsername:spark@qubership.com token:true id_token:true created:2024-12-06 04:50:41.614617414 +0000 UTC m=+59642.433001425 expires:2024-12-06 05:05:41.525826993 +0000 UTC m=+60542.344210998 refresh_token:true groups:[role:offline_access role:uma_authorization role:default-roles-e6426d1d-967f-4fae-ae3e-95dd08ad6c50]}.                                                                                                                                                                                                                                         |
| High | | logout/forced logout/login failed                         | Events are not reflected in the spark related logs.                                                                                                                                                                                                                                |
| High | Oauth2 Proxy | create session | 10.127.132.216:35528 - d99c946d160dc405026679d4e220a9cd - spark@qubership.com [2024/12/06 04:50:41] [AuthSuccess] Authenticated via OAuth2: Session{email:spark@qubership.com user:2affc30b-a549-4f91-bdbb-025afa2e9d03 PreferredUsername:spark@qubership.com token:true id_token:true created:2024-12-06 04:50:41.614617414 +0000 UTC m=+59642.433001425 expires:2024-12-06 05:05:41.525826993 +0000 UTC m=+60542.344210998 refresh_token:true groups:[role:offline_access role:uma_authorization role:default-roles-e6426d1d-967f-4fae-ae3e-95dd08ad6c50]}.                                          |
| High | | unauthorized event | There is no authorization in spark history. Authentication mechanism is used only.|
| Low | | change password | Events are not reflected in the spark related logs.|
| Low | | create/delete/modify user and group | Events are not reflected in the spark related logs.|
| Low | | delete/modify security policy provider | Not applicable for spark history server.|
| Low | | modify grants | There is no authorization in spark history. Authentication mechanism is used only.|
| Low | | grant system privilege or role | There is no authorization in spark history. Authentication mechanism is used only.|
| Low | Spark History Server | start/stop server-application | 24/12/05 12:17:05 INFO HistoryServer: Bound HistoryServer to 0.0.0.0, and started at http://spark-history-server-8594b6557d-4sp9t:18080|
| Low | Spark History Server | start/stop server-application | 24/12/05 12:17:05 INFO Utils: Successfully started service 'HistoryServerUI' on port 18080.|

## Session Management

Spark History Server does not support session management. For these purposes, it is recommended to integrate it with external user management systems.
Oauth2 Proxy has a mechanism to store the sessions based on cookies, but it is not possible to manage them. You may find more details in the external Oauth2 Proxy dicumentation at _[Session Storage](https://oauth2-proxy.github.io/oauth2-proxy/configuration/session_storage/)_.

