# Partie 2 — Démonstration de la résilience du cluster Kubernetes

Ce document décrit les tests de résilience réalisés sur le cluster TX Kubernetes, conformément aux besoins exprimés par le SiMDE, afin de démontrer que le service reste disponible face à différents types de pannes et de variations de charge.

Les tests ont été effectués sur des applications déployées avec plusieurs réplicas et un stockage persistant (Longhorn).

## Objectifs

- Vérifier qu’une panne d’un worker n’entraîne pas d’interruption significative du service

- Vérifier qu’une panne d’un nœud control-plane n’affecte pas les applications déjà en cours d’exécution

- Vérifier que le cluster supporte une augmentation de charge via la réplication automatique des applications

- Observer le comportement du stockage persistant en cas de perte de nœud

## Pré-requis communs

- Application déployée avec au moins 2 réplicas

- Réplicas répartis sur plusieurs nœuds

- Accès au cluster via kubectl

- Accès HTTP à l’application testée

- Stockage persistant via Longhorn

- Pendant chaque test, trois observations sont effectuées en parallèle :

- Accès utilisateur continu (requêtes HTTP avec horodatage)

- État et replanification des Pods

- État des volumes Longhorn

## Scénario A — Panne d’un worker

### Objectif

Démontrer qu’une panne d’un nœud worker n’entraîne pas d’interruption du service et que les Pods sont automatiquement replanifiés.

### Méthode

1. Démarrage d’un accès continu à l’application (requêtes HTTP répétées avec horodatage)

2. Observation en temps réel des Pods :

``` kubectl -n tx-shwet get pod -o wide -w ```


3. Mise hors service d’un worker via :

``` kubectl drain <worker> --ignore-daemonsets --delete-emptydir-data ```


4. Observation :

- Continuité des réponses HTTP

- Éviction des Pods sur le worker défaillant

- Recréation des Pods sur les autres nœuds disponibles

- Passage des volumes Longhorn à l’état degraded, puis récupération automatique

### Résultat attendu

- Le service reste accessible pendant toute la durée du test

- Les Pods sont automatiquement replanifiés

- Le stockage reste fonctionnel malgré une réduction temporaire de redondance

## Scénario B — Panne d’un nœud control-plane

### Objectif

Démontrer qu’une panne d’un control-plane n’affecte pas les services en cours d’exécution tant que le quorum etcd est respecté.

### Méthode

1. Maintien d’un accès continu à l’application

2. Arrêt d’un seul nœud control-plane (via l’hyperviseur)

3. Observation :

``` kubectl get node -w ```


4. Vérification que :

- L’application reste accessible

- Le cluster continue de répondre aux commandes Kubernetes

### Résultat attendu

- Aucune interruption du service

- Le cluster reste opérationnel

- La limite du quorum etcd est clairement identifiée (arrêt de plus d’un control-plane non testé)

## Scénario C — Réplication automatique et montée en charge

### Objectif

Démontrer que l’application peut être répliquée dynamiquement sous charge sans interruption du service.

### Méthode

1. Génération d’une charge simple par requêtes HTTP continues

2. Augmentation du nombre de réplicas :

``` kubectl -n tx-shwet scale deployment shwet --replicas=3 ```


3. Observation :

``` kubectl -n tx-shwet get pod -o wide -w ```


4. Vérification de la continuité de l’accès utilisateur pendant la création des nouveaux Pods

### Résultat attendu

- Les nouveaux Pods sont créés et planifiés automatiquement

- L’accès au service reste disponible pendant toute l’opération

- La montée en charge est gérée sans interruption visible

## Conclusion

Ces tests démontrent que :

- Le cluster est tolérant aux pannes de workers

- Une panne limitée de control-plane n’impacte pas les services

- La réplication des applications permet d’absorber une montée en charge

- Le stockage persistant reste utilisable même en mode dégradé et se rétablit automatiquement

L’ensemble des tests a été réalisé sans intervention manuelle sur les applications, en s’appuyant uniquement sur les mécanismes natifs de Kubernetes.