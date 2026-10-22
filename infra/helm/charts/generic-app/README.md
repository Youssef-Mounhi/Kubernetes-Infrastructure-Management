# Guide de Configuration Helm Values

Ce document explique les options de configuration disponibles dans le fichier de valeurs Helm et leurs objectifs.

## Paramètres de Base de l'Application

**appName** : Le nom de votre application, utilisé pour l'étiquetage et l'identification des ressources.

**namespace** : L'espace de noms Kubernetes où les ressources seront déployées. Utile pour l'isolation.

## Configuration du Déploiement

**replicaCount** : Nombre de réplicas de pods à exécuter. 1 par défaut.

### Configuration de l'Image

cf. https://kubernetes.io/docs/concepts/containers/images/

**image.repository** : Le chemin du dépôt d'images Docker.

**image.tag** : Le tag de version de l'image.

**image.pullPolicy** : Détermine quand Kubernetes télécharge l'image.

**containerPort** : Le port sur lequel votre application écoute à l'intérieur du conteneur (8080 dans cet exemple).

### Labels

cf. https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/

**labels.component** : Labels personnalisés pour organiser et sélectionner les ressources. Utile pour la supervision, le filtrage et l'application de politiques à des composants spécifiques.

### Contexte de Sécurité

**podSecurityContext** : Paramètres de sécurité pour le pod, cruciaux pour suivre le principe du moindre privilège. Il faut prendre en compte l'implémentation de l'image Docker.

- **runAsUser/runAsGroup** : Défini à 65534 (l'utilisateur `nobody`), garantissant que l'application ne s'exécute pas en tant que root, réduisant les risques de sécurité si le conteneur est compromis.
- **fsGroup** : Contrôle les permissions du système de fichiers pour les volumes montés.
- **runAsNonRoot** : Force le conteneur à ne pas s'exécuter en tant que root, ajoutant une couche de sécurité supplémentaire.

### Sondes de Santé

**probes.readiness** : Détermine quand un pod est prêt à recevoir du trafic. Cela empêche le routage de requêtes vers des pods qui ne sont pas complètement initialisés.

- **initialDelaySeconds** : Temps d'attente avant la première vérification (10s), permettant à l'application de démarrer.
- **periodSeconds** : Fréquence d'exécution de la vérification.
- **timeoutSeconds** : Temps maximum d'attente pour une réponse.
- **failureThreshold** : Nombre d'échecs consécutifs avant de marquer le pod comme non prêt.

**probes.liveness** : Détecte si l'application fonctionne toujours correctement. En cas d'échec, Kubernetes redémarrera le pod.

- Utilise des paramètres similaires aux sondes de readiness mais avec des délais plus longs (20s) pour éviter les redémarrages prématurés pendant les opérations normales.

### Gestion des Ressources

cf. https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

**resources** : Critique pour la stabilité du cluster et pour éviter la famine de ressources.

- **requests** : Ressources garanties allouées au pod. Utilisées par le planificateur Kubernetes pour placer les pods sur les nœuds appropriés.
  - **cpu** : 200m (0,2 cœur CPU) - exigence de base
  - **memory** : 256Mi - mémoire minimale nécessaire
- **limits** : Ressources maximales que le pod peut utiliser, empêchant les processus incontrôlés d'affecter les autres charges de travail.
  - **cpu** : 1000m (1 cœur CPU complet)
  - **memory** : 512Mi

Pourquoi vous en avez besoin : Sans limites de ressources, une seule application défaillante pourrait consommer toutes les ressources du cluster, affectant les autres services.

### Gestion de la Configuration

**useConfig** : Définir à `true` si votre application a besoin de variables d'environnement depuis une ConfigMap (pour la configuration non sensible comme les feature flags, les endpoints d'API, etc.).

**useSecret** : Définir à `true` si votre application a besoin de données sensibles depuis un Secret (pour les mots de passe, clés API, tokens, etc.).

Il faut d'abords générer le fichier `values-secret.yaml` via le script `scripts/inject-env-in-values.sh`.

### Stockage

cf. https://kubernetes.io/fr/docs/concepts/storage/volumes/

**volumes/volumeMounts** : Actuellement commentés mais disponibles quand vous avez besoin de stockage persistant.

Pourquoi vous pourriez en avoir besoin : Pour les applications qui stockent des fichiers, des uploads, des bases de données, ou toute donnée qui doit survivre aux redémarrages de pods. L'exemple montre le montage d'un PersistentVolumeClaim vers `/var/www/html/storage`, courant pour les applications web.

## Configuration du Service

cf. https://kubernetes.io/docs/concepts/services-networking/service/

**service.type** : `ClusterIP` rend le service accessible uniquement à l'intérieur du cluster. Utilisez `LoadBalancer` ou `NodePort` si vous avez besoin d'un accès externe sans Ingress.

**service.port** : Le port exposé par le service (80), qui peut différer du containerPort. Cela permet de standardiser les ports externes pendant que les applications utilisent différents ports internes.

**service.name** : Nom du port du service, utile pour les services multi-ports.

## Configuration de l'Ingress

cf. https://kubernetes.io/docs/concepts/services-networking/ingress/

**ingress.host** : Le nom de domaine pour accéder à votre application (ex: `test.tx.assos.utc.fr`). Vous aurez besoin d'une configuration DNS appropriée et d'un contrôleur Ingress dans votre cluster.

**pathPrefix** : (Commenté) Permet de servir l'application à un chemin spécifique comme `/api` au lieu de la racine.

**stripPathPrefix** : (Commenté) Indique s'il faut supprimer le préfixe de chemin avant de transférer les requêtes au service.

## Persistent Volume Claims (PVCs)

cf. https://kubernetes.io/fr/docs/concepts/storage/persistent-volumes/

Actuellement commenté mais fournit un exemple pour demander du stockage persistant. Le cluster utilise la solution Longhorn.

**pvcs[].name** : Identifiant pour la demande de stockage.

**pvcs[].storage** : Quantité de stockage demandée (2Gi dans l'exemple).

**pvcs[].storageClassName** : La classe de stockage à utiliser. Longhorn est mentionné comme valeur par défaut, qui est un stockage de blocs distribué cloud-native pour Kubernetes.

**pvcs[].accessModes** : Comment le volume peut être monté (`ReadWriteOnce` signifie qu'il peut être monté en lecture-écriture par un seul nœud).

Pourquoi vous en avez besoin : Essentiel pour les applications avec état comme les bases de données, les systèmes de stockage de fichiers, ou toute application nécessitant que les données persistent au-delà des cycles de vie des pods.

## Configuration du CronJob

Permet l'exécution de tâches planifiées.

**cronjob.enabled** : Active la ressource CronJob.

**cronjob.schedule** : Expression cron pour la planification (ex: `"*/5 * * * *"` s'exécute toutes les 5 minutes).

**cronjob.concurrencyPolicy** : `Forbid` empêche les exécutions de jobs qui se chevauchent, utile quand les jobs ne doivent pas s'exécuter simultanément.

**cronjob.successfulJobsHistoryLimit/failedJobsHistoryLimit** : Nombre d'enregistrements de jobs terminés à conserver pour le débogage.

**cronjob.ttlSecondsAfterFinished** : Temps de nettoyage automatique pour les jobs terminés (300 secondes = 5 minutes).

**cronjob.command** : La commande à exécuter dans le job planifié.

Pourquoi vous en avez besoin : Pour les tâches périodiques comme les sauvegardes, le nettoyage de données, la génération de rapports, ou toute opération de maintenance planifiée.

## Configuration Redis

L'utilisation de Redis sous Kubernetes n'est pas recommandé. Il faut plutôt envisager un déploiement externe et géré si son utilisation va au-delà du simple caching.

**redis.enabled** : Définir à `true` si votre application a besoin de Redis pour le cache, le stockage de sessions, ou comme broker de messages.

**redis.auth.password** : (Commenté) Mot de passe pour l'authentification Redis lorsqu'il est activé.