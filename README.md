
## Setting up the service account token for pulling images from registry.redhat.io
Needed for RH sso
Registry.redhat.io service account:

https://access.redhat.com/documentation/en-us/red_hat_single_sign-on/7.4/html/red_hat_single_sign-on_for_openshift_on_openjdk/get_started#image-streams-applications-templates

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: 11009103-sholly-ocp4-pull-secret
data:
  .dockerconfigjson: $DOCKERCONFIGJSON 
type: kubernetes.io/dockerconfigjson
```

`kubectl create -f sholly-ocp4-secret.yml --namespace=NAMESPACEHERE`

## Installing the RH SSO templates and imagestreams: 


```shell
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
```

or run `oc create` in the example above


# Installing ephemeral version of Red Hat SSO; 


`oc new-project sso-app-demo`

`oc policy add-role-to-user view system:serviceaccount:$(oc project -q):default

oc new-app --template=sso74-x509-https -p SSO_ADMIN_USERNAME=admin -p SSO_ADMIN_PASSWORD=cheese


When the installation is complete and the pods are ready: 

Log into RH SSO

Create a new realm, call it 'eap-demo'


Add a new User Federation -> LDAP

Vendor:  active directory

connection url: ldap://ad.lab.unixnerd.org

Users DN: cn=Users,DC=lab,DC=unixnerd,DC=org

Bind DN: CN=Administrator,CN=Users,DC=lab,DC=unixnerd,DC=org

Bind Credential: Administrator Password

Make sure to test the connection and authentication. 


## Automatically connecting a sample application to Active Directory-enabled RH SSO: 

The example is taken directly from : 


https://access.redhat.com/documentation/en-us/red_hat_single_sign-on/7.4/html/red_hat_single_sign-on_for_openshift_on_openjdk/tutorials#binary-builds

Create the project: 

oc new-project eap-app-demo

Add a role: 

oc policy add-role-to-user view system:serviceaccount:$(oc project -q):default

Get the ingress certificate from the openshift console, and save it. 


Create a keystore: 

`keytool -genkeypair -alias https -storetype JKS -keystore eapkeystore.jks`

Add the ingress certificate to our new keystore: 

`keytool -importcert -keystore eapkeystore.jks -storepass changeit -alias sso -trustcacert -file $INGRESS_CERTIFICATE`

Generate a jceks keystore: 

`keytool -genseckey -alias jgroups -storetype JCEKS -keystore eapjgroups.jceks`


Create secrets from both keystores, and link both secrets to the default serviceaccount: 

```
oc create secret generic eap-ssl-secret --from-file=eapkeystore.jks
oc create secret generic eap-jgroup-secret --from-file=eapjgroups.jceks
oc secrets link default eap-ssl-secret eap-jgroup-secret
```

in eap-demo realm, get public key from keys tab.

Create a role in Eap-demo  ->  roles, call it 'eap-user-role'

add eap-mgmt-user, set password , add all roles for realm-management

add eap-user, set password,add eap-user-role

From *eap-demo* realm, copy the public key: 
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6BNZ7fmJonIJOlE9iPAL/84bxnFzQ3MQcHrD/mnhjlkc9I/ALvV64tmTB94GbFDF6YOc0kgwoSR+QxDhSa5kDZa8Bcjas+WI4mVRB14qK/dNy0qA0qjmY++Hx+p42W9B6F70Gg49baNCZs9R8cTx2JVQirxeLkTpUUi8CFSM7RM9MYFSI6taOgoJIS9/djcV4tFmdyQyriO6zeJuBqVMNFbXZWyunBqhvNmnzgc8N/u0v3BS0Ydwjs7fGIR/ofFKjDBBFHRjuZuoyPZ8pSONSwZcncfy6jwPK41F72rqCx0V4ZlZ+l+lduKX1LGsGKa4IRVxwSF9zPZ0B368KVZR4QIDAQAB


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
 -p SSO_PUBLIC_KEY='MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6BNZ7fmJonIJOlE9iPAL/84bxnFzQ3MQcHrD/mnhjlkc9I/ALvV64tmTB94GbFDF6YOc0kgwoSR+QxDhSa5kDZa8Bcjas+WI4mVRB14qK/dNy0qA0qjmY++Hx+p42W9B6F70Gg49baNCZs9R8cTx2JVQirxeLkTpUUi8CFSM7RM9MYFSI6taOgoJIS9/djcV4tFmdyQyriO6zeJuBqVMNFbXZWyunBqhvNmnzgc8N/u0v3BS0Ydwjs7fGIR/ofFKjDBBFHRjuZuoyPZ8pSONSwZcncfy6jwPK41F72rqCx0V4ZlZ+l+lduKX1LGsGKa4IRVxwSF9zPZ0B368KVZR4QIDAQAB' \
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

