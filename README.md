# TrustKin

Prototype web mobile-first en français, construit sans dépendances de build. Les données de catalogue restent volontairement vides tant que TrustKin n'a pas fourni de vraies annonces et leurs photos.

## Ouvrir le prototype

Ouvrir `index.html` dans un navigateur. Les fichiers `styles.css`, `app.js`, les dossiers `logo/` et `voitures/`, ainsi que leurs chemins doivent rester à côté du fichier HTML.

## WhatsApp et réseaux sociaux

Le numéro TrustKin est configuré dans `app.js` : `243854541549`. Les boutons WhatsApp ouvrent ce numéro avec un message prérempli. Le formulaire ajoute les coordonnées et le sujet de la demande au message WhatsApp.

Les liens Facebook, Instagram et TikTok pointent provisoirement vers les pages d'accueil des plateformes. Remplacer leurs URLs dans `index.html` par les liens des profils officiels TrustKin dès qu'ils sont disponibles.

## Contenu avant publication

- Ajouter les visuels prévus dans `image/` : la bannière d'accueil, les illustrations de catégories et les photos des services. Le dossier est vide actuellement ; des illustrations CSS temporaires représentent certaines catégories.
- Fournir les photos authentiques des véhicules, logements et produits Apple avant de créer des annonces.
- Vérifier l'adresse, les horaires, les mentions légales et remplacer les liens sociaux provisoires par les profils officiels de TrustKin.
- Ne pas publier de témoignages ou de statistiques avant d'avoir des données vérifiées.

## Prochaine étape technique

Ce prototype statique n'inclut pas encore de backend, d'authentification ni d'espace d'administration. La migration de base de données se trouve dans `supabase/migrations/202610260001_initial_schema.sql`. Avant tout déploiement public, connecter les pages à Supabase via des routes serveur, configurer les règles de stockage d'images, la validation et la protection anti-spam, puis construire l'administration derrière Supabase Auth. Ne jamais placer la clé `service_role` dans du code navigateur.