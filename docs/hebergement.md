# Hébergement et authentification Decap

## Situation au 15 octobre 2026

> Mise à jour du 15 octobre : le compte Netlify est sur le plan Free à crédits (voir plus bas), et l'hébergement va migrer sur un VPS déjà loué pour un autre site. La section « Auto-hébergement sur un VPS avec Coolify » devient le plan retenu.

Le site est un Jekyll déployé sur Netlify (plan Starter gratuit) avec Decap CMS en backoffice. Decap utilise le backend `github` : chaque éditeur s'authentifie avec son compte GitHub via le service OAuth de Netlify, et ses publications sont des commits sur `main` signés de son nom.

### Problème rencontré

Les builds Netlify échouaient avec `Build failed: unrecognized Git contributor`. Le plan Starter n'autorise qu'un seul contributeur Git sur un dépôt privé. Netlify regarde l'auteur du commit qui déclenche le build : dès qu'un éditeur autre que le propriétaire publie depuis Decap, le build est refusé. Ajouter des collaborateurs côté GitHub ne change rien à ce comptage.

### Décision : dépôt public

La limite ne s'applique qu'aux dépôts privés. Le dépôt passe en public, sans aucun changement de configuration Decap ou Netlify.

Audit préalable de l'historique Git (28 commits, fichiers présents et supprimés) : aucun secret, aucun fichier `.env`, aucune clé ni token. Le seul contact dans le code est l'email public du collectif.

Conséquences à connaître :

- Les emails des auteurs de commits deviennent visibles dans l'historique. Chaque contributeur peut activer « Keep my email addresses private » dans ses réglages GitHub pour que ses futurs commits utilisent l'adresse `noreply`.
- Le dossier `assets/images_originals` (photos et captures non optimisées) est committé et donc public.

### Second problème : le plan Netlify à crédits

Le compte a été créé après le 4 septembre 2025, donc il est sur le plan Free à crédits et non sur l'ancien Starter à minutes de build. Alerte reçue le 14 octobre 2026 : « Low on credits – 250 credits remaining ».

| Poste                                                                   | Coût        |
| ----------------------------------------------------------------------- | ----------- |
| Budget mensuel, plafond dur, remis à zéro à chaque cycle de facturation | 300 crédits |
| Un déploiement en production (chaque publication Decap en déclenche un) | 15 crédits  |
| 1 Go de bande passante                                                  | 20 crédits  |
| 10 000 requêtes                                                         | 2 crédits   |
| Deploy previews, branch deploys, builds échoués                         | gratuit     |

Soit au mieux 20 publications par mois si personne ne visite le site. Une visite de l'accueil pesant 26 Mo (voir « Poids d'une visite »), 50 visites coûtent autant qu'une publication. À zéro, Netlify suspend le site jusqu'au cycle suivant : un pic de trafic peut couper le site, pas seulement les builds.

Décision : migrer sur le VPS déjà loué pour un autre site, avec Coolify, selon le plan décrit plus bas. Coût supplémentaire nul. Netlify reste en place pendant la bascule.

### Alternatives écartées

- **Netlify Pro** : contributeurs illimités, mais payant par membre, disproportionné pour ce site.
- **GitHub Pages** : exige aussi un dépôt public sur un compte gratuit, et ajoute un workflow Actions (le build natif de Pages n'accepte pas `jekyll-tailwind`) plus un proxy OAuth pour Decap, puisque le service OAuth de Netlify ne fonctionne que pour un site hébergé chez eux.
- **Cloudflare Pages** : gratuit, bande passante illimitée, 500 builds par mois, proxy OAuth possible en Worker gratuit (`sveltia-cms-auth` ou `decap-proxy`). Aurait été le choix sans VPS existant. Limite à connaître : 25 Mo par fichier, le teaser non compressé de 90 Mo ferait échouer le déploiement.

## Point d'attention : Decap chargé depuis un CDN

`admin/index.html` charge `decap-cms@^3.0.0` depuis unpkg. Toute version mineure publiée est servie immédiatement, sans action de notre part. Pour fiabiliser, héberger le bundle JS dans `admin/` et le mettre à jour volontairement.

Le même fichier charge encore le widget Netlify Identity. Il est inutile avec le backend `github` et Netlify Identity est déprécié : la ligne peut être supprimée.

## Plan retenu : auto-hébergement sur un VPS avec Coolify

Écrit à l'origine pour garder le dépôt privé (GitHub n'impose aucune limite de collaborateurs sur les dépôts privés gratuits, la contrainte venait uniquement de Netlify). Retenu en octobre 2026 pour sortir du plan à crédits, sur un VPS déjà loué pour un autre site. Le dépôt peut repasser en privé à cette occasion.

### Ce que Decap attend d'un serveur d'authentification

Le backend `github` expose deux options : `base_url` et `auth_endpoint` (par défaut `https://api.netlify.com` et `auth`). Le protocole tient en quatre étapes :

```
1. Decap ouvre une popup sur {base_url}/{auth_endpoint}?provider=github&scope=repo
2. Le serveur redirige vers github.com/login/oauth/authorize (client_id, scope repo, state)
3. GitHub rappelle le serveur avec ?code=... ; le serveur l'échange contre un access_token
4. Le serveur rend une page HTML qui exécute :
   window.opener.postMessage("authorizing:github", "*")
   puis, à la réponse de Decap :
   window.opener.postMessage('authorization:github:success:{"token":"...","provider":"github"}', origin)
```

Deux routes, un échange HTTP, une page HTML. Decap s'adapte en changeant seulement `base_url` dans `admin/config.yml`. De nombreuses implémentations de référence existent (Go, Node, Cloudflare Worker) et servent de modèle.

### Architecture envisagée

- **VPS** type Hetzner CX22 (environ 4 € par mois) avec Coolify, qui gère Docker, le reverse proxy et les certificats Let's Encrypt.
- **GitHub reste l'hébergeur Git**, en privé. Coolify s'y connecte via une GitHub App et redéploie à chaque push sur `main`, donc à chaque publication Decap. Aucune forge Git à maintenir.
- **Site statique** : Dockerfile en deux étapes, image Ruby pour `bundle exec jekyll build`, puis nginx alpine qui sert `_site`. Préférable au buildpack statique de Coolify à cause du binaire Tailwind tiré par `jekyll-tailwind`.
- **Serveur d'auth** : une seconde application Coolify en Sinatra ou Roda, avec `GITHUB_CLIENT_ID` et `GITHUB_CLIENT_SECRET` en variables d'environnement, et une OAuth App GitHub dont l'URL de callback pointe dessus. Rails ou Hanami sont surdimensionnés pour deux routes (image lourde, 150 à 200 Mo de RAM à vide contre 50 Mo pour Sinatra).
- **Decap** auto-hébergé dans `admin/` plutôt que chargé depuis unpkg.

### Option sans GitHub

Forgejo sur Coolify et le backend `gitea` de Decap, qui supporte le flux PKCE : plus besoin de serveur d'auth, Decap parle directement à Forgejo. En contrepartie, la forge Git, ses sauvegardes et ses mises à jour de sécurité sont à notre charge. Écartée pour un site de cette taille.

### Maintenance à prévoir

- Durcissement initial du VPS : SSH par clé, pare-feu, fail2ban, sauvegarde de la configuration Coolify.
- En régime de croisière, une à deux heures par mois : mises à jour du système, de Coolify et de Docker, espace disque, renouvellement des certificats.
- Pas de CDN ; un nginx sur un VPS suffit pour ce site.
- Points de fragilité, par ordre de probabilité : mise à jour de Coolify modifiant le proxy, mise à jour majeure de Decap changeant le protocole popup (stable depuis Netlify CMS 1.x), changement de l'API OAuth GitHub (très rare).

## Poids d'une visite et images

### Mesure au 15 octobre 2026

Première visite de l'accueil, mesurée sur le build local. Ni lazy loading ni `srcset` : tout ce qui est référencé se charge, et la vidéo en autoplay muet se télécharge en entier.

| Poste                                                                      | Poids            |
| -------------------------------------------------------------------------- | ---------------- |
| Teaser vidéo (`teaser_n164_compressed.webm` ou `.mp4` selon le navigateur) | 20,9 à 22,5 Mo   |
| 24 images webp (films, membres, à propos)                                  | 4,8 Mo           |
| 3 polices woff2                                                            | 104 Ko           |
| HTML + CSS + JS                                                            | 70 Ko            |
| **Total**                                                                  | **26 à 27,5 Mo** |

La vidéo fait 82 % du total. Les images sont presque toutes en 2048 px de large pour un affichage de 600 px environ en vignette. Deux photos pèsent à elles seules 1,5 Mo (`img_20250730_112334.webp`, `img_20250813_205223.webp`). Le logo de la section à propos est servi en PNG depuis `images_originals` alors qu'un webp existe.

Fichiers déployés mais utilisés nulle part : `assets/teaser_n164.mp4` (90 Mo) et le dossier `assets/images_originals` (50 Mo). À exclure du build.

### Chaîne actuelle

Les contributeurs envoient leurs photos depuis Decap dans `assets/images`, telles quelles (JPEG de téléphone, plusieurs Mo). Le script `scripts/optimize_image.rb` (image_processing + ruby-vips, 2048 px max, webp qualité 85) doit être relancé à la main, puis `scripts/update_image_refs.rb` corrige les références. Rien ne se fait au build.

### Options

- **Compression à l'upload avec Sveltia CMS.** Remplaçant de Decap qui lit le même `config.yml`. Quelques lignes dans `media_libraries.default.config.transformations` convertissent en webp et redimensionnent dans le navigateur avant le commit. Rend le script manuel inutile et garde le dépôt léger. Aucun changement de template. Nécessite le même proxy OAuth que Decap (`sveltia-cms-auth` est fait pour), donc s'intègre à la migration VPS sans travail supplémentaire.
- **Tailles d'affichage au build avec `jekyll_picture_tag`.** Génère les variantes (par exemple 600, 1200, 1800 px) et la balise `<picture>` avec `srcset`. Repose sur ruby-vips, exige libvips sur la machine de build (une ligne dans le Dockerfile, non garanti sur Netlify). Remplace la balise `<img>` par un tag Liquid dans `_includes/films.html`, `_includes/about.html`, `_layouts/film.html` et `_layouts/membre.html`. Dernière version 2.1.3 de juin 2025 : gem peu actif, à surveiller. Gain estimé : images de l'accueil de 4,8 Mo à environ 1 Mo.
- **Allègements sans dépendance.** Recompresser le teaser vers 5 à 7 Mo en 720p. Ajouter `loading="lazy"` sur les images sous la ligne de flottaison. Redimensionner les deux grosses photos. Servir le logo en webp.

### Décision

Les tailles d'affichage au build sont reportées : il faut vérifier le rendu sur toutes les pages et ce n'est pas la priorité. À faire dans l'ordre, au fil de la migration :

1. Exclure du build le teaser non compressé et `images_originals`.
2. Recompresser le teaser, poste principal.
3. Lazy loading et retouche des deux grosses photos.
4. Sveltia avec compression à l'upload, en même temps que le proxy OAuth.
5. `jekyll_picture_tag` plus tard, quand il y aura le temps de passer chaque page.
