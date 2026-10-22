# Migration du déploiement Kubernetes vers Helm

## Contexte

Initialement, l’application **Shwet** était déployée sur le cluster Kubernetes via des manifestes YAML écrits manuellement (`Deployment`, `Service`, `Ingress`, `ConfigMap`, `Secret`, `PVC`, `CronJob`, etc.).

Cette approche fonctionnait, mais présentait plusieurs limites :

- Difficulté de maintenir et faire évoluer les manifestes
- Duplication de configurations entre environnements
- Gestion manuelle des Secrets et du versioning
- Déploiement non reproductible et peu standardisé

L’objectif de ce travail est donc de **migrer le déploiement existant vers Helm**, afin de rendre l’infrastructure plus modulaire, maintenable et réutilisable.

---

## Objectifs de la migration

- Remplacer les manifestes Kubernetes statiques par un **Helm chart**
- Externaliser la configuration via `values.yaml`
- Séparer clairement les paramètres sensibles (`values-secret.yaml`)
- Permettre des déploiements **reproductibles**, **versionnés** et **rollbackables**
- Faciliter l’installation, la mise à jour et la maintenance de l’application

---

## Principe de fonctionnement avec Helm

Le déploiement repose désormais sur un **Helm chart dédié à Shwet**, qui génère dynamiquement les ressources Kubernetes à partir de templates.

Les éléments suivants sont gérés par Helm :

- `Deployment` (application web)
- `Service`
- `Ingress` (Traefik)
- `ConfigMap` (variables d’environnement non sensibles)
- `Secret` (variables sensibles)
- `PersistentVolumeClaim` (volumes RWX via Longhorn)
- `CronJob` (scheduler Laravel)
- Labels et métadonnées Helm pour le suivi des releases

---

## Structure du chart Helm

```
infra/helm/charts/shwet/
├── Chart.yaml
├── values.yaml
├── values-secret.yaml # non versionné
├── templates/
│ ├── deployment.yaml
│ ├── service.yaml
│ ├── ingress.yaml
│ ├── pvc.yaml
│ ├── cronjob.yaml
│ ├── configmap-env.yaml
│ ├── phpfpm-configmap.yaml
│ ├── secret.yaml
│ └── _helpers.tpl
```

- `values.yaml` : configuration applicative et infrastructurelle
- `values-secret.yaml` : secrets (exclu du dépôt Git)
- `templates/` : templates Helm générant les ressources Kubernetes

---

## Déploiement de l’application

### Pré-requis

- Helm installé
- Accès au cluster Kubernetes
- Namespace cible existant ou créé à l’installation

### Installation / Mise à jour

```bash
helm upgrade --install shwet infra/helm/charts/shwet \
  -n tx-shwet \
  -f infra/helm/charts/shwet/values.yaml \
  -f infra/helm/charts/shwet/values-secret.yaml
```

### Helm prend en charge :

- l’installation initiale

- les mises à jour incrémentales

- l’historique des releases

- les rollbacks si nécessaire

## Avantages apportés par Helm

- Déploiement reproductible et standardisé

- Séparation claire entre code, configuration et secrets

- Facilitation des mises à jour et des tests

- Possibilité de rollback rapide en cas de problème

- Base réutilisable pour d’autres applications ou environnements

## État actuel

- L’ensemble des ressources Kubernetes est désormais géré par Helm

- Les volumes persistants sont correctement montés (RWX)

- L’application démarre correctement avec plusieurs réplicas

- Le CronJob Laravel est fonctionnel

- L’accès via Ingress Traefik est opérationnel

## Conclusion

Cette migration marque le passage d’un déploiement Kubernetes manuel vers une approche Helm plus robuste et maintenable, adaptée à un environnement de production et à une gestion collaborative de l’infrastructure.

Elle constitue également une base solide pour l’automatisation future (CI/CD) et la réutilisation du chart pour d’autres services.