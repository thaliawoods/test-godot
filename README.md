# HTTPS — Expérience interactive MIDI et mondes 3D

## Présentation

HTTPS est un projet interactif développé avec Godot Engine, combinant audio en temps réel, environnements 3D et photogrammétrie.

Le projet transforme un contrôleur MIDI en interface de navigation et de composition. Chaque interaction génère simultanément du son, des transformations spatiales et des apparitions visuelles, créant une expérience hybride entre jeu vidéo, instrument et installation artistique.

Développé en collaboration avec une artiste dans le cadre d’une résidence aux Ateliers Médicis, le projet explore internet comme un système de liens entre territoires, mémoires et individus.

---

## Fonctionnement

L’expérience repose sur une interaction directe entre le geste et le système. Les pads du contrôleur MIDI permettent de naviguer entre différents mondes, tandis que les touches déclenchent l’apparition d’objets 3D issus de captations photogrammétriques. La vélocité influence l’intensité sonore, introduisant une dimension expressive dans l’interaction.

L’utilisateur évolue dans un espace navigable et observe les transformations générées en temps réel. Le système ne repose sur aucune timeline prédéfinie : l’expérience se construit dynamiquement à partir des actions.

---

## Système de mondes

Le projet est structuré en plusieurs environnements (`world_01` à `world_05`), chacun possédant une identité visuelle et des paramètres spécifiques. Le passage d’un monde à l’autre est instantané et permet de fragmenter l’expérience en différentes ambiances tout en conservant une continuité d’interaction.

Chaque monde contient sa propre bibliothèque d’objets et ses propres règles de perception, renforçant son autonomie et sa cohérence.

---

## Photogrammétrie

Les objets intégrés dans les environnements sont issus de captations réelles en photogrammétrie. Ils sont instanciés dynamiquement en réponse aux interactions de l’utilisateur, permettant de construire l’espace progressivement et d’introduire une matérialité issue du réel dans un environnement numérique.

---

## Système audio

Le son est déclenché en temps réel à partir des événements MIDI. L’intensité sonore dépend de la vélocité, ce qui permet de conserver une expressivité proche de celle d’un instrument musical. Les sons peuvent se superposer librement, créant une structure temporelle émergente.

---

## Architecture

Le projet repose sur une architecture modulaire développée sous Godot Engine.

Le nœud principal (`Main`) coordonne l’ensemble des systèmes. `MidiRouter` interprète les signaux MIDI et les convertit en événements exploitables. `WorldManager` gère le chargement et la configuration des environnements. `PhotogrammetryManager` est responsable de l’instanciation dynamique des objets 3D. `AudioManager` gère le déclenchement et la lecture des sons.

Cette organisation permet une grande flexibilité et facilite l’ajout de nouveaux contenus.

---

## Flux de fonctionnement

```
Entrée MIDI
   ↓
MidiRouter
   ↓
Dispatch des événements
   ↓
WorldManager → changement de monde
PhotogrammetryManager → apparition d’objet
AudioManager → lecture sonore
```

---

## Enjeux techniques

Le développement du projet a impliqué plusieurs problématiques, notamment l’intégration du MIDI en temps réel dans un moteur 3D, l’instanciation dynamique de scènes, la synchronisation entre audio et visuel, ainsi que la gestion des collisions et de la physique dans des environnements variés. La gestion de fichiers photogrammétriques volumineux et la mise en place d’une architecture modulaire ont également constitué des enjeux importants.

---

## Installation

### Prérequis

- Godot Engine 4.x (testé sur 4.6+)  
- Contrôleur MIDI (recommandé)  
- macOS, Windows ou Linux  

### Installation du projet

```bash
git clone https://github.com/your-repo/https-project.git
cd https-project
```

Ouvrir le projet dans Godot :

```
Import → sélectionner project.godot → Open
```

---

## Lancer le projet

1. Connecter un contrôleur MIDI  
2. Lancer la scène principale  
3. Interagir avec le système :
   - Pads : changement de monde  
   - Touches : déclenchement des objets et des sons  

En cas d’absence de périphérique MIDI, les logs permettent d’identifier les appareils disponibles.

---

## Structure du projet

```
/audio
/photogrammetry
/worlds
/scripts
    AudioManager.gd
    MidiRouter.gd
    WorldManager.gd
    PhotogrammetryManager.gd
Main.tscn
```

---

## Intentions artistiques

Le projet explore la transformation d’un instrument musical en interface spatiale, ainsi que la relation entre geste, son et environnement. L’intégration de photogrammétries permet d’introduire des fragments du réel dans un système interactif, créant une tension entre capture et simulation.

HTTPS se situe à la frontière entre jeu vidéo, installation artistique et instrument expérimental.

---

## Perspectives

Le projet est conçu comme une base évolutive. Il pourrait intégrer à terme une spatialisation sonore avancée, des interactions entre objets, des environnements génératifs, ou encore une dimension multi-utilisateur et une mise en espace en contexte d’exposition.

---


## Contact

https://thalia-woods.vercel.app
