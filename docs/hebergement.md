# Hébergement et authentification Decap

## Situation au 14 octobre 2026

Le site est un Jekyll déployé sur Netlify (plan Starter gratuit) avec Decap CMS en backoffice. Decap utilise le backend `github` : chaque éditeur s'authentifie avec son compte GitHub via le service OAuth de Netlify, et ses publications sont des commits sur `main` signés de son nom.

### Problème rencontré

Les builds Netlify échouaient avec `Build failed: unrecognized Git contributor`. Le plan Starter n'autorise qu'un seul contributeur Git sur un dépôt privé. Netlify regarde l'auteur du commit qui déclenche le build : dès qu'un éditeur autre que le propriétaire publie depuis Decap, le build est refusé. Ajouter des collaborateurs côté GitHub ne change rien à ce comptage.

### Décision : dépôt public

La limite ne s'applique qu'aux dépôts privés. Le dépôt passe en public, sans aucun changement de configuration Decap ou Netlify.

Audit préalable de l'historique Git (28 commits, fichiers présents et supprimés) : aucun secret, aucun fichier `.env`, aucune clé ni token. Le seul contact dans le code est l'email public du collectif.

Conséquences à connaître :

- Les emails des auteurs de commits deviennent visibles dans l'historique. Chaque contributeur peut activer « Keep my email addresses private » dans ses réglages GitHub pour que ses futurs commits utilisent l'adresse `noreply`.
- Le dossier `assets/images_originals` (photos et captures non optimisées) est committé et donc public.

### Alternatives écartées

- **Netlify Pro** : contributeurs illimités, mais payant par membre, disproportionné pour ce site.
- **GitHub Pages** : exige aussi un dépôt public sur un compte gratuit, et ajoute un workflow Actions (le build natif de Pages n'accepte pas `jekyll-tailwind`) plus un proxy OAuth pour Decap, puisque le service OAuth de Netlify ne fonctionne que pour un site hébergé chez eux.

## Point d'attention : Decap chargé depuis un CDN

`admin/index.html` charge `decap-cms@^3.0.0` depuis unpkg. Toute version mineure publiée est servie immédiatement, sans action de notre part. Pour fiabiliser, héberger le bundle JS dans `admin/` et le mettre à jour volontairement.

Le même fichier charge encore le widget Netlify Identity. Il est inutile avec le backend `github` et Netlify Identity est déprécié : la ligne peut être supprimée.

## Piste en réserve : auto-hébergement sur un VPS avec Coolify

Cette architecture permettrait de garder le dépôt privé, car GitHub n'impose aucune limite de collaborateurs sur les dépôts privés gratuits. La contrainte venait uniquement de Netlify.

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
