Needed for RH sso
Registry.redhat.io service account:

https://access.redhat.com/documentation/en-us/red_hat_single_sign-on/7.4/html/red_hat_single_sign-on_for_openshift_on_openjdk/get_started#image-streams-applications-templates


apiVersion: v1
kind: Secret
metadata:
  name: 11009103-sholly-ocp4-pull-secret
data:
  .dockerconfigjson: $DOCKERCONFIGJSON 
type: kubernetes.io/dockerconfigjson

kubectl create -f sholly-ocp4-secret.yml --namespace=NAMESPACEHERE

for resource in sso74-image-stream.json \
  sso74-https.json \
  sso74-postgresql.json \
  sso74-postgresql-persistent.json \
  sso74-x509-https.json \
  sso74-x509-postgresql-persistent.json
do
  oc replace -n openshift --force -f \
  https://raw.githubusercontent.com/jboss-container-images/redhat-sso-7-openshift-image/sso74-dev/templates/${resource}
done

or do create..

oc new-project sso-app-demo

oc policy add-role-to-user view system:serviceaccount:$(oc project -q):default

oc new-app --template=sso74-x509-https -p SSO_ADMIN_USERNAME=admin -p SSO_ADMIN_PASSWORD=cheese

Once done, add a new User Federation -> LDAP

vendor active directory

connection url: ldap://ad.lab.unixnerd.org

Users DN: cn=Users,DC=lab,DC=unixnerd,DC=org

Bind DN: CN=Administrator,CN=Users,DC=lab,DC=unixnerd,DC=org

Bind Credential: Administrator Password

Test Connection

Test authentication

https://access.redhat.com/documentation/en-us/red_hat_single_sign-on/7.4/html/red_hat_single_sign-on_for_openshift_on_openjdk/tutorials#binary-builds

oc new-project eap-app-demo

oc policy add-role-to-user view system:serviceaccount:$(oc project -q):default

export ingress certificate and save it. 

```
keytool -genkeypair -alias https -storetype JKS -keystore eapkeystore.jks
keytool -importcert -keystore eapkeystore.jks -storepass changeit -alias sso -trustcacert -file $INGRESS_CERTIFICATE
keytool -genseckey -alias jgroups -storetype JCEKS -keystore eapjgroups.jceks
```
Create secrets: 

```
oc create secret generic eap-ssl-secret --from-file=eapkeystore.jks
oc create secret generic eap-jgroup-secret --from-file=eapjgroups.jceks
oc secrets link default eap-ssl-secret eap-jgroup-secret
```

Create new realm in rh sso.  Name it 'Eap-demo'

in eap-demo realm, get public key from keys tab.

Create a role in Eap-demo  ->  roles, call it 'eap-user-role'

add eap-mgmt-user, set password , add all roles for realm-management

add eap-user, set password,add eap-user-role

now deploy eap73-sso-s2i:

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

