export ENV=$(terraform workspace show)
open/create backendfiles/*.conf file > put bucket and region value as backend.default.conf.txt (according to Environment / terraform workspace) 
terraform init -backend-config=backendfiles/backend.${ENV}.conf
IF ALREADY HAVE A LOCAL BACKECD USE:terraform init -migrate-state -backend-config=backendfiles/backend.${ENV}.conf