# Shwet — Déploiement Kubernetes (Traefik + Longhorn)

Ce dossier contient les manifests Kubernetes nécessaires pour déployer **Shwet (Laravel)** dans le namespace `tx-shwet`, exposé via **Traefik Ingress** et avec stockage persistant via **Longhorn PVC**.

## Vue d’ensemble

- Namespace : `tx-shwet`
- Image : `registry.gitlab.utc.fr/simde/shwet:latest`
- Service HTTP interne : `ClusterIP shwet:80` → conteneur `8005`
- Ingress : `shwet-tx.assos.utc.fr` (IngressClass `traefik`)
- Stockage persistant (Longhorn) :
  - `shwet-documents` (2Gi) → `/var/www/html/storage/app/public/documents`
  - `shwet-logs` (1Gi) → `/var/www/html/storage/logs`
- Tâches planifiées :
  - CronJob `shwet-scheduler` : `*/5 * * * *` (toutes les 5 minutes) → `php artisan schedule:run`

---

## Manifests : rôle de chaque fichier

### `00-namespace-config.yaml`
Contient 2 ressources :

1) **Namespace `tx-shwet`**  
Isole toutes les ressources Shwet (Deployment, Service, Ingress, PVC, CronJob, …).

2) **ConfigMap `shwet-env`** (variables non sensibles)  
Paramètres applicatifs (exemples) :
- Laravel : `APP_NAME`, `APP_ENV`, `APP_DEBUG`, `APP_URL`, `LOG_CHANNEL`, `LOG_LEVEL`
- DB (sans mot de passe) : `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`
- API : `UTCRAWL_API_URL`
- Chemins/stockage : `DOCUMENTS_STORAGE_PATH`, `OLD_DATA_STORAGE_PATH`, `USER_ROLES_STORAGE_PATH`
- OAuth : `OAUTH_URL`, `OAUTH_REDIRECT_URI`, `OAUTH_SCOPES`, `OAUTH_AUTHORIZATION_URL`, etc.
- Drivers : `CACHE_DRIVER`, `QUEUE_CONNECTION`, `SESSION_DRIVER`, …
- Mail (partie non sensible) : `MAIL_HOST`, `MAIL_PORT`, `MAIL_FROM_ADDRESS`, …
- Front : `VITE_APP_NAME`, `ASSET_URL`

---

### `01-secret.yaml`
**Secret `shwet-secret`** (informations sensibles) :
- `APP_KEY`
- `DB_PASSWORD`
- `UTCRAWL_API_KEY`
- `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`
- `MAIL_USERNAME`, `MAIL_PASSWORD`

> Reco : éviter de versionner des secrets en clair en prod (SealedSecrets / ExternalSecrets / injection au déploiement).

---

### `05-phpfpm-config.yaml`
**ConfigMap `shwet-phpfpm`**  
Fournit un `www.conf` pour PHP-FPM (pool `[www]`) monté dans le conteneur via `subPath` :
- Mount : `/etc/php83/php-fpm.d/www.conf`

---

### `50-longhorn-pvc.yaml`
2 **PersistentVolumeClaim** (StorageClass `longhorn`) :

- `shwet-documents` : `2Gi`, `ReadWriteOnce`
- `shwet-logs` : `1Gi`, `ReadWriteOnce`

Ces PVC sont montés par le Deployment pour rendre persistants documents et logs.

> Note : `ReadWriteOnce` implique généralement qu’un volume est monté en écriture par un seul nœud à la fois. Si vous augmentez `replicas`, il faut valider la stratégie de stockage (RWX/S3/séparation).

---

### `10-deployment.yaml`
**Deployment `shwet`** (replicas = `1`) :
- `imagePullPolicy: Always`
- Commande : `sh -c /var/www/html/laravel-setup.sh`
- Ports : `8005`
- `envFrom` :
  - ConfigMap `shwet-env`
  - Secret `shwet-secret`
- Readiness probe : `GET /` sur `8005` (initialDelay 40s)
- Resources :
  - requests : `100m` / `256Mi`
  - limits : `500m` / `512Mi`
- Volumes / mounts :
  - `shwet-phpfpm` → `/etc/php83/php-fpm.d/www.conf` (subPath `www.conf`)
  - PVC `shwet-documents` → `/var/www/html/storage/app/public/documents`
  - PVC `shwet-logs` → `/var/www/html/storage/logs`
- SecurityContext Pod : `runAsUser: 0`, `runAsGroup: 0`

---

### `20-service.yaml`
**Service `shwet`** (type `ClusterIP`) :
- Port `80` (name: `http`)
- `targetPort: 8005`
- Selector : `app=shwet`

---

### `30-ingress.yaml`
**Ingress `shwet`** :
- `ingressClassName: traefik`
- Host : `shwet-tx.assos.utc.fr`
- Path : `/` (Prefix) → Service `shwet:80`
- TLS : non configuré dans ce manifest (à ajouter si cert-manager/Traefik TLS est en place)

---

### `40-cronjob.yaml`
**CronJob `shwet-scheduler`** :
- Schedule : `*/5 * * * *`
- `concurrencyPolicy: Forbid`
- Historique : `successfulJobsHistoryLimit: 3`, `failedJobsHistoryLimit: 3`
- Nettoyage : `ttlSecondsAfterFinished: 300`
- Conteneur :
  - image : `registry.gitlab.utc.fr/simde/shwet:latest`
  - `imagePullPolicy: IfNotPresent`
  - commande : `cd /var/www/html && php artisan schedule:run`
  - `envFrom` : `shwet-env` + `shwet-secret`
- SecurityContext Pod : `runAsUser: 0`, `runAsGroup: 0`

---

## Procédure de déploiement (ordre recommandé)

```bash
# 1) Namespace + ConfigMap
kubectl apply -f 00-namespace-config.yaml

# 2) Secret
kubectl apply -f 01-secret.yaml

# 3) PVC Longhorn (à créer avant le Deployment)
kubectl apply -f 50-longhorn-pvc.yaml

# 4) Config PHP-FPM
kubectl apply -f 05-phpfpm-config.yaml

# 5) App + réseau
kubectl apply -f 10-deployment.yaml
kubectl apply -f 20-service.yaml
kubectl apply -f 30-ingress.yaml

# 6) Cron
kubectl apply -f 40-cronjob.yaml
