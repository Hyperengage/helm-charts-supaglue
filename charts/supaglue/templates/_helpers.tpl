{{/* vim: set filetype=mustache: */}}
{{- define "supaglue.name" -}}
{{- template "common.names.name" . -}}
{{- end -}}

{{- define "supaglue.chart" -}}
{{- template "common.names.chart" . -}}
{{- end -}}

{{- define "supaglue.fullname" -}}
{{- template "common.names.fullname" . -}}
{{- end -}}

{{/*
Create the name of the service account
*/}}
{{- define "supaglue.serviceAccountName" -}}
{{ default (include "supaglue.fullname" .) .Values.serviceAccount.name }}
{{- end -}}

{{/*
Define the service account as needed
*/}}
{{- define "supaglue.serviceAccount" -}}
{{- if .Values.serviceAccount.create -}}
serviceAccountName: {{ include "supaglue.serviceAccountName" . }}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified component name from the full app name and a component name.
We truncate the full name at 63 - 1 (last dash) - len(component name) chars because some Kubernetes name fields are limited to this (by the DNS naming spec)
and we want to make sure that the component is included in the name.
*/}}
{{- define "supaglue.componentname" -}}
{{- $global := index . 0 -}}
{{- $component := index . 1 | trimPrefix "-" -}}
{{- printf "%s-%s" (include "supaglue.fullname" $global | trunc (sub 62 (len $component) | int) | trimSuffix "-" ) $component | trimSuffix "-" -}}
{{- end -}}

{{- define "supaglue.databaseName" -}}
{{- if .Values.postgresql.enabled -}}
    {{- template "postgresql.database" .Subcharts.postgresql -}}
{{- else -}}
    {{- required "A value for postgresql.auth.database must be set." .Values.postgresql.auth.database -}}
{{- end -}}
{{- end -}}

{{- define "supaglue.databaseUsername" -}}
{{- if .Values.postgresql.enabled -}}
    {{- template "postgresql.username" .Subcharts.postgresql -}}
{{- else -}}
    {{- required "A value for postgresql.auth.username must be set." .Values.postgresql.auth.username -}}
{{- end -}}
{{- end -}}

{{- define "supaglue.databasePassword" -}}
{{- required "A value for global.postgres.auth.password must be set." (default .Values.global.postgresql.auth.password .Values.postgresql.auth.password) -}}
{{- end -}}

{{- define "supaglue.databasePort" -}}
{{- if .Values.postgresql.enabled -}}
    {{- template "postgresql.service.port" .Subcharts.postgresql -}}
{{- else -}}
    {{- required "A value for postgresql.port must be set." .Values.postgresql.port -}}
{{- end -}}
{{- end -}}

{{- define "supaglue.databaseHost" -}}
{{- default (printf "%s-postgresql.%s.svc.cluster.local" .Chart.Name $.Release.Namespace) .Values.postgresql.host  -}}
{{- end -}}

{{- define "supaglue.temporalPort" -}}
{{- if .Values.temporal.enabled -}}
    {{- template "temporal.frontend.grpcPort" .Subcharts.temporal  -}}
{{- else -}}
    {{- required "A value for temporal.port must be set." .Values.temporal.port -}}
{{- end -}}
{{- end -}}

{{- define "supaglue.temporalHost" -}}
{{- default (printf "%s-temporal-frontend.%s.svc.cluster.local" .Chart.Name $.Release.Namespace) .Values.temporal.host -}}
{{- end -}}

{{- define "supaglue.databaseUrl" -}}
{{- $database := include "supaglue.databaseName" . -}}
{{- $username := include "supaglue.databaseUsername" . -}}
{{- $password := urlquery (include "supaglue.databasePassword" .) -}}
{{- $host := include "supaglue.databaseHost" . -}}
{{- $port := include "supaglue.databasePort" . -}}
{{- printf "postgres://%s:%s@%s:%s/%s" $username $password $host $port $database -}}
{{- end -}}


{{- define "supaglue.managedDatabaseUrl" -}}
{{- $database := .Values.managedDatabase.name -}}
{{- $username := .Values.managedDatabase.username -}}
{{- $password := .Values.managedDatabase.password -}}
{{- $host := .Values.managedDatabase.host -}}
{{- $port := .Values.managedDatabase.port -}}
{{- printf "postgres://%s:%s@%s:%s/%s" $username $password $host $port $database -}}
{{- end -}}

{{- define "supaglue.syncWorker.databaseUrl" -}}
{{- $databaseUrl := include "supaglue.databaseUrl" . -}}
{{- $connectionLimit := ((.Values.syncWorker.db).parameters).connectionLimit -}}
{{- $poolTimeout := ((.Values.syncWorker.db).parameters).poolTimeout -}}
{{- $sslCert := empty ((.Values.syncWorker.db).parameters).sslCert | ternary nil (urlquery ((.Values.syncWorker.db).parameters).sslCert)  -}}
{{- $sslMode := ((.Values.syncWorker.db).parameters).sslMode -}}
{{- $sslIdentity := ((.Values.syncWorker.db).parameters).sslIdentity -}}
{{- $sslPassword := ((.Values.syncWorker.db).parameters).sslPassword -}}
{{- $sslAccept := ((.Values.syncWorker.db).parameters).sslAccept -}}
{{- $params := dict "connection_limit" $connectionLimit "pool_timeout" $poolTimeout "sslcert" $sslCert "sslmode" $sslMode "sslidentity" $sslIdentity "sslpassword" $sslPassword "sslaccept" $sslAccept -}}
{{- $lastIndex := sub (len (keys $params)) 1 -}}
{{- print $databaseUrl "?" -}}
{{- range $index, $key := keys $params -}}
  {{- $value := get $params $key -}}
  {{- if $value -}}
    {{- print $key "=" $value -}}
    {{- if ne $index $lastIndex -}}
      {{- print "&" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}


{{- define "supaglue.syncWorker.managedDatabaseUrl" -}}
{{- $databaseUrl := include "supaglue.managedDatabaseUrl" . -}}
{{- $connectionLimit := ((.Values.syncWorker.db).parameters).connectionLimit -}}
{{- $poolTimeout := ((.Values.syncWorker.db).parameters).poolTimeout -}}
{{- $sslCert := empty ((.Values.syncWorker.db).parameters).sslCert | ternary nil (urlquery ((.Values.syncWorker.db).parameters).sslCert)  -}}
{{- $sslMode := ((.Values.syncWorker.db).parameters).sslMode -}}
{{- $sslIdentity := ((.Values.syncWorker.db).parameters).sslIdentity -}}
{{- $sslPassword := ((.Values.syncWorker.db).parameters).sslPassword -}}
{{- $sslAccept := ((.Values.syncWorker.db).parameters).sslAccept -}}
{{- $params := dict "connection_limit" $connectionLimit "pool_timeout" $poolTimeout "sslcert" $sslCert "sslmode" $sslMode "sslidentity" $sslIdentity "sslpassword" $sslPassword "sslaccept" $sslAccept -}}
{{- $lastIndex := sub (len (keys $params)) 1 -}}
{{- print $databaseUrl "?" -}}
{{- range $index, $key := keys $params -}}
  {{- $value := get $params $key -}}
  {{- if $value -}}
    {{- print $key "=" $value -}}
    {{- if ne $index $lastIndex -}}
      {{- print "&" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "supaglue.api.databaseUrl" -}}
{{- $databaseUrl := include "supaglue.databaseUrl" . -}}
{{- $connectionLimit := ((.Values.api.db).parameters).connectionLimit -}}
{{- $poolTimeout := ((.Values.api.db).parameters).poolTimeout -}}
{{- $sslCert := empty ((.Values.api.db).parameters).sslCert | ternary nil (urlquery ((.Values.api.db).parameters).sslCert) -}}
{{- $sslMode := ((.Values.api.db).parameters).sslMode -}}
{{- $sslIdentity := ((.Values.api.db).parameters).sslIdentity -}}
{{- $sslPassword := ((.Values.api.db).parameters).sslPassword -}}
{{- $sslAccept := ((.Values.api.db).parameters).sslAccept -}}
{{- $params := dict "connection_limit" $connectionLimit "pool_timeout" $poolTimeout "sslcert" $sslCert "sslmode" $sslMode "sslidentity" $sslIdentity "sslpassword" $sslPassword "sslaccept" $sslAccept -}}
{{- $lastIndex := sub (len (keys $params)) 1 -}}
{{- print $databaseUrl "?" -}}
{{- range $index, $key := keys $params -}}
  {{- $value := get $params $key -}}
  {{- if $value -}}
    {{- print $key "=" $value -}}
    {{- if ne $index $lastIndex -}}
      {{- print "&" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "supaglue.api.managedDatabaseUrl" -}}
{{- $databaseUrl := include "supaglue.managedDatabaseUrl" . -}}
{{- $connectionLimit := ((.Values.managedDatabase).parameters).connectionLimit -}}
{{- $poolTimeout := ((.Values.managedDatabase).parameters).poolTimeout -}}
{{- $sslCert := empty ((.Values.managedDatabase).parameters).sslCert | ternary nil (urlquery ((.Values.managedDatabase).parameters).sslCert) -}}
{{- $sslMode := ((.Values.managedDatabase).parameters).sslMode -}}
{{- $sslIdentity := ((.Values.managedDatabase).parameters).sslIdentity -}}
{{- $sslPassword := ((.Values.managedDatabase).parameters).sslPassword -}}
{{- $sslAccept := ((.Values.managedDatabase).parameters).sslAccept -}}
{{- $params := dict "connection_limit" $connectionLimit "pool_timeout" $poolTimeout "sslcert" $sslCert "sslmode" $sslMode "sslidentity" $sslIdentity "sslpassword" $sslPassword "sslaccept" $sslAccept -}}
{{- $lastIndex := sub (len (keys $params)) 1 -}}
{{- print $databaseUrl "?" -}}
{{- range $index, $key := keys $params -}}
  {{- $value := get $params $key -}}
  {{- if $value -}}
    {{- print $key "=" $value -}}
    {{- if ne $index $lastIndex -}}
      {{- print "&" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "supaglue.salesforcePubSub.databaseUrl" -}}
{{- $databaseUrl := include "supaglue.databaseUrl" . -}}
{{- $connectionLimit := ((.Values.salesforcePubSub.db).parameters).connectionLimit -}}
{{- $poolTimeout := ((.Values.salesforcePubSub.db).parameters).poolTimeout -}}
{{- $sslCert := empty ((.Values.salesforcePubSub.db).parameters).sslCert | ternary nil (urlquery ((.Values.syncWorker.db).parameters).sslCert) -}}
{{- $sslMode := ((.Values.salesforcePubSub.db).parameters).sslMode -}}
{{- $sslIdentity := ((.Values.salesforcePubSub.db).parameters).sslIdentity -}}
{{- $sslPassword := ((.Values.salesforcePubSub.db).parameters).sslPassword -}}
{{- $sslAccept := ((.Values.salesforcePubSub.db).parameters).sslAccept -}}
{{- $params := dict "connection_limit" $connectionLimit "pool_timeout" $poolTimeout "sslcert" $sslCert "sslmode" $sslMode "sslidentity" $sslIdentity "sslpassword" $sslPassword "sslaccept" $sslAccept -}}
{{- $lastIndex := sub (len (keys $params)) 1 -}}
{{- print $databaseUrl "?" -}}
{{- range $index, $key := keys $params -}}
  {{- $value := get $params $key -}}
  {{- if $value -}}
    {{- print $key "=" $value -}}
    {{- if ne $index $lastIndex -}}
      {{- print "&" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "supaglue.secretName" -}}
{{- if .Values.existingSecret -}}
    {{- printf "%s" (tpl .Values.existingSecret $) -}}
{{- else -}}
    {{- print "supaglue-secret" -}}
{{- end -}}
{{- end -}}

{{- define "supaglue.deploymentId" -}}
{{- required "A value for deploymentId must be set." .Values.deploymentId -}}
{{- end -}}
