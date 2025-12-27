# mysecondbrainv1
🧠 Brain Capture (Frontend)

Composant d'ingestion mobile pour l'architecture "Second Brain AI-Git".

Ce projet est l'application mobile (Flutter) conçue pour capturer rapidement des URL et des notes, puis les déposer directement dans votre dépôt GitHub ("Source de Vérité Unique"), sans passer par un serveur intermédiaire complexe.

🏗 Architecture & Philosophie

Ce projet respecte strictement la Constitution du Second Brain :

Capture First, Process Later : L'application sert uniquement à "déposer" l'information. Le traitement (Scraping/IA) est asynchrone.

Stateless & Serverless : L'application n'a pas de base de données. Elle agit comme un Client GitHub pur.

Souveraineté : Vos données vont directement de votre téléphone à votre dépôt privé GitHub.

Flux de données (Data Flow)

Utilisateur : Saisit une URL + une Note + Choisit un modèle IA (DeepSeek/Gemini/Claude).

App Mobile :

Génère un fichier JSON standardisé.

Upload ce fichier dans le dossier 00_Inbox/_drafts/ via l'API GitHub.

Backend (Script Python - À venir) :

Détecte le nouveau fichier JSON.

Scrape le contenu, le résume via IA, et génère la note Markdown finale.

🚀 Installation & Démarrage

Prérequis

Flutter SDK (v3.10+) installé.

Un compte GitHub.

Un Personal Access Token (PAT) GitHub.

Création : Settings > Developer settings > Personal access tokens > Tokens (classic).

Droits requis : repo (pour lire et écrire dans votre dépôt privé).

Installation (Développement)

Pour tester rapidement avec le téléphone branché en USB :

Cloner ce projet :

git clone [https://github.com/votre-user/brain-capture.git](https://github.com/votre-user/brain-capture.git)
cd brain-capture



Installer les dépendances :

flutter pub get



Lancer l'application (Mode Debug) :

Sur Mobile (Recommandé) : Branchez votre téléphone (Mode Développeur activé).

flutter run



Sur Web (Pour tester) :

flutter run -d chrome



Installation Permanente (Android APK)

Pour installer l'application définitivement sur votre téléphone (utilisation sans câble) :

Construire l'APK (Release) :

flutter build apk --release


Installer sur le téléphone :

Assurez-vous que le téléphone est branché.

Lancez la commande d'installation :

flutter install


Alternative : Copiez manuellement le fichier généré (build/app/outputs/flutter-apk/app-release.apk) sur votre téléphone et ouvrez-le.

⚙️ Configuration de l'App

Au premier lancement, allez dans l'onglet Réglages et renseignez les informations suivantes :

| Champ | Description | Exemple |
| GitHub Token | Votre clé secrète (PAT). Stockée localement sur le téléphone. | ghp_A1b2C3... |
| Username | Votre nom d'utilisateur GitHub. | jdupont |
| Repository | Le nom exact de votre dépôt de notes. | second-brain |
| Chemin Inbox | Le dossier où déposer les brouillons. | 00_Inbox/_drafts |

Note de sécurité : Le token est nettoyé automatiquement (trim()) pour éviter les erreurs de copier-coller (espaces invisibles).

📄 Protocole de Données

L'application génère des fichiers nommés selon le format :
YYYYMMDD-HHMM_slug-url.json

Structure du JSON (Draft)

C'est ce fichier que le script Backend devra traiter.

{
  "url": "[https://korben.info/article-interessant.html](https://korben.info/article-interessant.html)",
  "added_at": "2025-12-22T14:30:00.000Z",
  "note": "À lire pour le projet de migration. Vérifier la partie sécu.",
  "model_pref": "deepseek"
}



model_pref : Indique au backend quel "cerveau" utiliser pour le traitement :

deepseek : Pour du code ou de la structure technique.

gemini : Pour la vitesse et le contexte général.

claude : Pour la nuance et la rédaction.

🛠 Stack Technique

Framework : Flutter (Dart).

Http : Package http pour les appels API REST GitHub.

Stockage Local : Package shared_preferences pour persister la configuration (Token/Repo).

Design : Material 3 (Adaptatif Light/Dark mode).

✅ État du Projet

$$x$$

 Interface UI (Capture & Settings).

$$x$$

 Connexion API GitHub (PUT request).

$$x$$

 Gestion des erreurs et nettoyage des inputs.

$$$$

 Partage natif (Intent) depuis d'autres apps (Android/iOS).

$$$$

 Mode Offline (Mise en cache si pas de réseau).
