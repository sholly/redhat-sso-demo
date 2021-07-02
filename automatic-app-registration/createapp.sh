#!/bin/sh 

oc new-app --template eap73-sso-s2i \
 -p APPLICATION_NAME=sso \
 -p HOSTNAME_HTTP=sample-jsp.eap-app-demo.apps.ocp4.lab.unixnerd.org \
 -p HOSTNAME_HTTPS=secure-sample-jsp.eap-app-demo.apps.ocp4.lab.unixnerd.org \
 -p SSO_URL=https://sso-sso-app-demo.apps.ocp4.lab.unixnerd.org/auth \
 -p SSO_SERVICE_URL=https://sso-sso-app-demo.apps.ocp4.lab.unixnerd.org/auth \
 -p SSO_REALM=eap-demo \
 -p SSO_USERNAME=eap-mgmt-user \
 -p SSO_PASSWORD="RedHat123" \
 -p SSO_PUBLIC_KEY=''
 -p SSO_TRUSTSTORE=eapkeystore.jks \
 -p SSO_TRUSTSTORE_PASSWORD=changeit \
 -p SSO_TRUSTSTORE_SECRET=eap-ssl-secret \
 -p HTTPS_KEYSTORE=eapkeystore.jks \
 -p HTTPS_PASSWORD=changeit \
 -p HTTPS_SECRET=eap-ssl-secret \
 -p JGROUPS_ENCRYPT_KEYSTORE=eapjgroups.jceks \
 -p JGROUPS_ENCRYPT_NAME=jgroups \
 -p JGROUPS_ENCRYPT_PASSWORD=changeit \
 -p JGROUPS_ENCRYPT_SECRET=eap-jgroup-secret \
 -p JGROUPS_CLUSTER_PASSWORD=changeit \
 -p SSO_SAML_CERTIFICATE_NAME=https \
 -p SSO_SAML_KEYSTORE_SECRET=eap-ssl-secret \
 -p SSO_SAML_KEYSTORE_PASSWORD=changeit \
 -p SSO_SAML_KEYSTORE=eapkeystore.jks \
 -p SSO_DISABLE_SSL_CERTIFICATE_VALIDATION=true
