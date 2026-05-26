Ниже — расширенный список сайтов и репозиториев с бесплатными ассетами, Godot-шаблонами, билдами, аддонами и CI/CD-конфигами. Для коммерческих проектов проверяй лицензию каждого конкретного ассета: **CC0 / MIT / Apache-2.0** — самые удобные; **CC-BY** требует указания автора; **CC-BY-SA / GPL** могут создавать ограничения.

## 1. Godot-ядро, официальные ассеты, демо и аддоны

| Ресурс                                                               | Что брать                                                | Почему полезно                                                        |
| -------------------------------------------------------------------- | -------------------------------------------------------- | --------------------------------------------------------------------- |
| **Godot Engine** ([Godot Engine][1])                                 | сам движок, экспортные шаблоны, документация             | бесплатный open-source движок; актуальная ветка на сайте сейчас 4.6.x |
| **Godot Asset Library / AssetLib** ([Godot Engine documentation][2]) | аддоны, скрипты, инструменты, шаблоны прямо из редактора | официальный каталог user-submitted ресурсов для Godot                 |
| **Godot Asset Library Web** ([Godot Engine][3])                      | свежие плагины, шаблоны, 2D/3D tools                     | удобно смотреть новые бесплатные MIT/Community-аддоны                 |
| **Awesome Godot** ([GitHub][4])                                      | curated list: игры, плагины, скрипты, аддоны             | один из лучших стартовых списков по Godot                             |
| **Godot Demo Projects** ([GitHub][5])                                | официальные demo-проекты с `project.godot`               | можно разбирать сцены, физику, UI, 2D/3D, input, networking           |
| **Godot Demo Projects Web Preview** ([godotengine.github.io][6])     | веб-запуск официальных демо                              | быстро посмотреть, как работает механика без установки                |
| **GodotAssetLibrary.com** ([godotassetlibrary.com][7])               | подборки бесплатных Godot assets                         | неофициальный удобный каталог “best free Godot assets”                |
| **Godot Marketplace — Free Assets** ([godotmarketplace.com][8])      | бесплатные Godot-ассеты и плагины                        | маркетплейс с отдельным разделом free assets                          |

## 2. Готовые Godot-шаблоны, билды и CI/CD-конфиги

| Ресурс                                                                | Что брать                                        | Для чего                                         |
| --------------------------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------ |
| **Maaack / Godot Game Template** ([GitHub][9])                        | main menu, options, pause, credits, scene loader | быстрый старт игры на Godot 4.x                  |
| **godot-ci GitHub Action / Docker** ([GitHub][10])                    | GitHub Actions / GitLab CI для экспорта билдов   | автоматические сборки Windows/Linux/Web/Itch.io  |
| **Godot Export Action** ([GitHub][11])                                | GitHub Action для экспорта игры                  | кеширует Godot и export templates, удобно для CI |
| **Build Godot Action** ([GitHub][12])                                 | workflow для сборок Linux/Windows/macOS          | полезно, если нужен простой export pipeline      |
| **Godot Template Project with CI/CD** ([GitHub][13])                  | готовый репозиторий с CI/CD и деплоем на itch.io | стартовый production-like шаблон                 |
| **Godot 4.1+ Template GitHub Repository** ([Godot Forum][14])         | GitHub Pages + Windows/Linux/Web artifacts       | быстрый шаблон для публикации Web-билдов         |
| **Godot CI to Itch.io guide** ([itch.io][15])                         | пример `export_presets.cfg` и HTML export        | полезно для itch.io Web-публикации               |
| **Automating Godot 4 Android Exports** ([The Digital Spell Site][16]) | Android `.aab`, keystore, GitHub Actions         | если нужен Android-пайплайн                      |
| **Codemagic Godot CI/CD guide** ([Codemagic blog][17])                | экспортные пресеты и командная сборка            | полезно для мобильных билдов и CI                |

Минимальная структура репозитория под Godot:

```text
/game
  project.godot
  export_presets.cfg
  /addons
  /assets
	/2d
	/3d
	/audio
	/ui
	/licenses
  /scenes
  /scripts
  /autoload
  /config
.github
  /workflows
	export-web.yml
	export-desktop.yml
	export-android.yml
```

## 3. Большие бесплатные библиотеки 2D / 3D / UI ассетов

| Ресурс                                        | Что брать                                           | Лицензия / нюанс                                           |
| --------------------------------------------- | --------------------------------------------------- | ---------------------------------------------------------- |
| **Kenney Assets** ([kenney.nl][18])           | 2D, 3D, UI, audio, textures, starter kits           | один из лучших источников CC0-style ассетов для прототипов |
| **Kenney на itch.io** ([itch.io][19])         | asset bundles, game kits                            | удобно скачивать наборами                                  |
| **itch.io Free Game Assets** ([itch.io][20])  | пиксель-арт, UI, тайлсеты, звуки, music packs       | лицензии разные, проверять каждый пак                      |
| **itch.io Godot-tag assets** ([itch.io][21])  | ассеты, уже помеченные как Godot-friendly           | удобно искать Godot-ready пакеты                           |
| **itch.io CC0 assets** ([webgamedev.com][22]) | CC0-паки по тегам                                   | лучший фильтр для коммерческих прототипов                  |
| **OpenGameArt** ([OpenGameArt.org][23])       | 2D, 3D, музыка, SFX, тайлы, sprites                 | много свободных лицензий: CC0, CC-BY, CC-BY-SA, OGA-BY     |
| **CraftPix Free** ([CraftPix.net][24])        | 2D game art, GUI, sprites, tilesets                 | есть free и paid; проверять условия конкретного товара     |
| **Game-icons.net** ([game-icons.net][25])     | SVG/PNG иконки для инвентаря, скиллов, UI           | CC-BY 3.0, нужна атрибуция                                 |
| **Quaternius** ([quaternius.com][26])         | low-poly 3D models, characters, vehicles, buildings | заявлены бесплатные CC0 3D-модели                          |
| **Kay Lousberg / KayKit** ([itch.io][27])     | low-poly packs, characters, dungeons, nature        | много бесплатных 3D-паков                                  |
| **Poly Haven** ([Poly Haven][28])             | HDRI, textures, 3D models                           | 100% free CC0, без регистрации                             |
| **ambientCG** ([ambientcg.com][29])           | PBR materials, HDRI, models                         | очень полезно для 3D-уровней и окружения                   |
| **Mixamo** ([mixamo.com][30])                 | rigged characters, skeletal animations              | удобно для быстрого прототипа 3D-персонажей                |

## 4. Аудио: SFX, музыка, ambience

| Ресурс                                           | Что брать                                | Нюанс                                                       |
| ------------------------------------------------ | ---------------------------------------- | ----------------------------------------------------------- |
| **Sonniss GameAudioGDC Archive** ([SONNISS][31]) | большие бесплатные SFX-бандлы            | royalty-free, commercial use, no attribution по их условиям |
| **Sonniss GDC 2026 Bundle** ([SONNISS][32])      | свежий GDC 2026 пакет SFX                | 7.47GB+, 347+ WAV, no attribution по странице               |
| **Freesound** ([Freesound][33])                  | one-shot SFX, ambience, Foley, UI sounds | Creative Commons лицензии разные: CC0/CC-BY/другие          |
| **OpenGameArt Audio** ([OpenGameArt.org][23])    | музыка, loop tracks, SFX                 | хорош для ретро/инди/фэнтези                                |
| **Pixabay Sound Effects** ([Pixabay][34])        | royalty-free game SFX                    | удобно для прототипов, но лицензию проверять отдельно       |

## 5. Шейдеры, VFX, terrain, dialogue, gameplay systems

| Ресурс                                                            | Что брать                                                  | Для чего                                       |
| ----------------------------------------------------------------- | ---------------------------------------------------------- | ---------------------------------------------- |
| **GDQuest Demos / Godot Shaders** ([GitHub][35])                  | 2D/3D shaders с playable demos                             | эффекты, материалы, визуальные эксперименты    |
| **Awesome Godot — Plugins/Addons** ([GitHub][4])                  | dialogue tools, terrain tools, subtitles, scripts          | хороший каталог системных решений              |
| **Terrain3D** через списки популярных Godot 4 addons ([Blog][36]) | editable terrain system                                    | если делаешь 3D-локации, открытый мир, острова |
| **Dialogue Manager** через популярные Godot addons ([Reddit][37]) | branching dialogue editor/runtime                          | диалоги, NPC, квесты                           |
| **Godot Asset Library — свежие tools** ([Godot Engine][38])       | save system, minimap, input buffer, dialog systems, SQLite | быстрый поиск готовых gameplay-модулей         |

## 6. Инструменты для создания ассетов бесплатно

| Ресурс                                        | Что делать                                                               |
| --------------------------------------------- | ------------------------------------------------------------------------ |
| **Blender** ([Blender][39])                   | 3D-модели, анимации, рендеры, low-poly, rigging, glTF/GLB export в Godot |
| **Material Maker** ([Material Maker][40])     | procedural PBR materials, textures, node-based материалки                |
| **Material Maker на itch.io** ([itch.io][41]) | downloadable “name your own price” версия                                |
| **Piskel** ([Piskel][42])                     | pixel art, sprites, animated GIF, spritesheets                           |
| **LibreSprite** ([LibreSprite][43])           | open-source редактор спрайтов и анимаций                                 |
| **Leshy SpriteSheet Tool** ([Leshy Labs][44]) | упаковка и редактирование sprite sheets / texture atlases                |
| **Laigter** ([itch.io][45])                   | normal maps, specular maps, parallax maps для 2D sprites                 |
| **Laigter GitHub** ([GitHub][46])             | исходники и open-source версия инструмента                               |

## 7. Что я бы выбрал как “бесплатный стартовый набор” под Godot

Для **2D mobile / casual / match / puzzle**:
Kenney + itch.io Free Godot + Game-icons.net + Piskel + Leshy + Sonniss + Godot Game Template.

Для **3D low-poly / planet builder / social sim**:
Quaternius + KayKit + Poly Haven + ambientCG + Blender + Mixamo + Material Maker + Terrain3D.

Для **быстрого production-пайплайна**:
Godot 4.6.x + Maaack Game Template + `export_presets.cfg` + godot-ci или Godot Export Action + itch.io Web deploy + GitHub Releases для desktop builds.

Для **чистого коммерческого прототипа без юридической боли**:
приоритетно бери **CC0/MIT/Apache-2.0**: Kenney, Quaternius, Poly Haven, ambientCG, часть itch.io CC0, часть OpenGameArt CC0, MIT-шаблоны Godot. Всё CC-BY складывай в отдельный `CREDITS.md`.

## 8. Практичный чек-лист перед использованием ассетов

1. Сохраняй рядом с ассетом файл лицензии или скрин/страницу источника.
2. Веди `assets/licenses/credits.md`: автор, название пака, лицензия, ссылка-источник, дата скачивания.
3. Не смешивай GPL-аддоны с коммерческим кодом без понимания последствий.
4. Для маркетинговой версии игры лучше заменить “очевидные бесплатные ассеты” на кастомные или переработанные.
5. Для Godot 4 проверяй совместимость аддона: Godot 3.x плагины часто требуют адаптации.

[1]: https://godotengine.org/?utm_source=chatgpt.com "Godot Engine - Free and open source 2D and 3D game engine"
[2]: https://docs.godotengine.org/en/stable/community/asset_library/what_is_assetlib.html?utm_source=chatgpt.com "About the Asset Library - Godot Docs"
[3]: https://godotengine.org/asset-library/asset?utm_source=chatgpt.com "Godot Asset Library"
[4]: https://github.com/godotengine/awesome-godot?utm_source=chatgpt.com "godotengine/awesome-godot: A curated list of free/ ..."
[5]: https://github.com/godotengine/godot-demo-projects?utm_source=chatgpt.com "godotengine/godot-demo-projects"
[6]: https://godotengine.github.io/godot-demo-projects/?utm_source=chatgpt.com "Official Godot demos exported to Web"
[7]: https://godotassetlibrary.com/?utm_source=chatgpt.com "Godot Asset Library - The Best Assets, All Free"
[8]: https://godotmarketplace.com/?utm_source=chatgpt.com "Godot Assets Marketplace – All you need in one place"
[9]: https://github.com/Maaack/Godot-Game-Template?utm_source=chatgpt.com "Maaack/Godot-Game-Template"
[10]: https://github.com/marketplace/actions/godot-ci?utm_source=chatgpt.com "godot-ci · Actions · GitHub Marketplace"
[11]: https://github.com/marketplace/actions/godot-export?utm_source=chatgpt.com "Godot Export · Actions · GitHub Marketplace"
[12]: https://github.com/marketplace/actions/build-godot?utm_source=chatgpt.com "Build Godot · Actions · GitHub Marketplace"
[13]: https://github.com/kristijandraca/godot-template?utm_source=chatgpt.com "Godot Template project with CI/CD"
[14]: https://forum.godotengine.org/t/godot-4-1-template-github-repository-w-ci-cd-with-github-pages-deployment-and-windows-linux-release/41456?utm_source=chatgpt.com "Godot 4.1+ Template GitHub Repository w CI/CD with ..."
[15]: https://murphysdad.itch.io/survive-the-island/devlog/406823/godot-ci-to-publish-from-github-to-itchio?utm_source=chatgpt.com "Godot CI to Publish From Github to Itch.io - MurphysDad"
[16]: https://thedigitalspell.com/godot-github-actions-2/?utm_source=chatgpt.com "Automating Godot 4 Android Exports with GitHub Actions (II)"
[17]: https://blog.codemagic.io/godot-games-cicd/?utm_source=chatgpt.com "Setting up CI/CD for a Godot game"
[18]: https://kenney.nl/assets?utm_source=chatgpt.com "Assets · Kenney"
[19]: https://kenney-assets.itch.io/?utm_source=chatgpt.com "Kenney (Assets) - itch.io"
[20]: https://itch.io/game-assets/free?utm_source=chatgpt.com "Top free game assets - itch.io"
[21]: https://itch.io/game-assets/free/tag-godot?utm_source=chatgpt.com "Top free game assets tagged Godot"
[22]: https://www.webgamedev.com/assets/asset-stores?utm_source=chatgpt.com "Asset Stores"
[23]: https://opengameart.org/?utm_source=chatgpt.com "OpenGameArt.org |"
[24]: https://craftpix.net/?srsltid=AfmBOoolrdnCxbOhdhHR8KYgVw7eKIQdn7W4psLrlo6ej7OiTONKCNCS&utm_source=chatgpt.com "CraftPix.net: 2D Game Assets Store & Free"
[25]: https://game-icons.net/?utm_source=chatgpt.com "Game-icons.net: 4180 free SVG and PNG icons for your ..."
[26]: https://quaternius.com/?utm_source=chatgpt.com "Quaternius • Free Game Assets"
[27]: https://kaylousberg.itch.io/?utm_source=chatgpt.com "Kay Lousberg - itch.io"
[28]: https://polyhaven.com/?utm_source=chatgpt.com "Poly Haven"
[29]: https://ambientcg.com/?utm_source=chatgpt.com "ambientCG - Free Textures, HDRIs and Models"
[30]: https://www.mixamo.com/?utm_source=chatgpt.com "Mixamo"
[31]: https://sonniss.com/gameaudiogdc/?utm_source=chatgpt.com "Royalty Free Sound Effects Archive: GameAudioGDC"
[32]: https://gdc.sonniss.com/?utm_source=chatgpt.com "GDC GAME AUDIO BUNDLE 2026 - SONNISS"
[33]: https://freesound.org/?utm_source=chatgpt.com "Freesound"
[34]: https://pixabay.com/sound-effects/search/game/?utm_source=chatgpt.com "Download Free Game Sound Effects"
[35]: https://github.com/gdquest-demos?utm_source=chatgpt.com "GDQuest Demos"
[36]: https://garciamarquez.dev/posts/godot-popular-assets/?utm_source=chatgpt.com "Most Popular Godot 4 Addons (by Github stars)"
[37]: https://www.reddit.com/r/godot/comments/1gvr4bu/most_popular_godot_4_asset_library_addons/?utm_source=chatgpt.com "Most Popular Godot 4 Asset Library Addons"
[38]: https://godotengine.org/asset-library/asset?max_results=500&page=0&sort=updated&utm_source=chatgpt.com "Asset Library"
[39]: https://www.blender.org/?utm_source=chatgpt.com "Blender - The Free and Open Source 3D Creation Software ..."
[40]: https://www.materialmaker.org/?utm_source=chatgpt.com "Material Maker"
[41]: https://rodzilla.itch.io/material-maker?utm_source=chatgpt.com "Material Maker by RodZilla - itch.io"
[42]: https://www.piskelapp.com/?utm_source=chatgpt.com "Piskel - Free online sprite editor"
[43]: https://libresprite.github.io/?utm_source=chatgpt.com "LibreSprite"
[44]: https://www.leshylabs.com/apps/sstool/?utm_source=chatgpt.com "Leshy SpriteSheet Tool - Online Sprite Sheet & Texture ..."
[45]: https://azagaya.itch.io/laigter?utm_source=chatgpt.com "Laigter by azagaya - Itch.io"
[46]: https://github.com/azagaya/laigter?utm_source=chatgpt.com "azagaya/laigter - automatic normal map generator for sprites!"
Для классической **3-в-ряд игры на Godot** лучший бесплатный стартовый билд сейчас:

# Рекомендованный билд №1: **Kenney Starter Kit Match-3**

Это самый удачный базовый вариант, потому что он уже сделан под **Godot 4.6**, содержит понятный код, анимации, звуки, частицы, кастомные курсоры и 2D-спрайты с CC0-лицензией. Сам код выложен под MIT License, то есть его удобно брать как основу коммерческого прототипа. ([GitHub][1])

## Почему именно он

| Критерий                                      | Оценка                                                 |
| --------------------------------------------- | ------------------------------------------------------ |
| Godot 4.x                                     | Да, Godot 4.6                                          |
| Бесплатный                                    | Да                                                     |
| Коммерчески удобный                           | Да: MIT для кода, CC0 для 2D-спрайтов                  |
| Уже есть core match-3                         | Да                                                     |
| Есть анимации / звук / частицы                | Да                                                     |
| Подходит для быстрой переделки под свой стиль | Да                                                     |
| Подходит как MVP-база                         | Да                                                     |
| Подходит как production-база без доработки    | Нет, нужно расширять мета-игру, уровни, UI, прогрессию |

**Вывод:** брать как основной билд для ядра игры.

Команда:

```bash
git clone https://github.com/KenneyNL/Starter-Kit-Match-3.git
```

---

# Идеальная сборка проекта

Я бы делал не просто на одном шаблоне, а так:

```text
Godot 4.6
+
Kenney Starter Kit Match-3
+
Maaack Godot Game Template
+
свои ассеты / UI / уровни / мета-прогрессия
+
GitHub Actions export pipeline
```

## 1. Core gameplay

**База:** Kenney Starter Kit Match-3.
В нем уже есть базовая логика поля, swap через drag, визуалы, эффекты и простая структура проекта. ([GitHub][1])

Что оставить:

```text
grid logic
tile swap
match detection
fall/refill
animations
sounds
particles
basic board setup
```

Что переписать под себя:

```text
level goals
boosters
special pieces
moves counter
combo scoring
tutorial logic
economy
daily rewards
map progression
```

---

## 2. Game shell / меню / настройки

К Kenney-билду лучше добавить **Maaack/Godot-Game-Template**. Он не про match-3, а про нормальную оболочку игры: главное меню, options, pause, credits, scene loader, persistent settings, keyboard/mouse, gamepad, UI sound controller, music controller, saving/loading и level progress manager. Он поддерживает Godot 4.6 и совместим с 4.3+. ([GitHub][2])

Это даст сразу:

```text
main menu
settings
pause menu
credits
loading screen
level manager
win / lose windows
save/load
audio settings
scene transitions
```

Команда:

```bash
git clone https://github.com/Maaack/Godot-Game-Template.git
```

**Практически:** Kenney используем как gameplay-сцену, Maaack — как каркас приложения.

---

# Альтернативы, которые тоже можно изучить

## 1. Match3 Board — хороший вариант как логическая библиотека

**Match3 Board 2.1.0** в Godot Asset Library — это MIT-библиотека под Godot 4.4, которая дает core-логику для match-3, чтобы не писать сложную механику поля с нуля. ([Godot Engine][3])

Подходит, если ты хочешь не готовую игру, а чистый reusable-модуль:

```text
board logic
match rules
swap validation
core mechanics
```

Минус: это не полноценный красивый билд игры, а скорее техническая библиотека.

## 2. luiz734/match3_game — полезный учебный референс

Это простой, но полностью функциональный match-3 проект на Godot 4. В README указаны документированные core-компоненты `match_3_core.gd` и `grid.gd`, drag adjacent pieces, shuffle button, lose condition и MIT License. ([GitHub][4])

Хорошо использовать как второй референс по архитектуре.

## 3. makifdb/godot-match3-template — старый, но MIT

Это Godot Match3 Game Template под Godot 4.0, MIT License, но проект небольшой, старее и менее сильный как база, чем Kenney Starter Kit. ([GitHub][5])

Можно смотреть для сравнения, но не брать как главный билд.

## 4. gitbrent/godot-match-3 — не советую как коммерческую основу

Это классический match-3 на Godot/GDScript 4.2, но лицензия **GPL-2.0**, поэтому для коммерческого проекта лучше не брать его код в основу. ([GitHub][6])

---

# Итоговый выбор

## Бери так:

**Основной билд:**
**Kenney Starter Kit Match-3** — ядро механики.

**Оболочка игры:**
**Maaack Godot Game Template** — меню, настройки, прогресс, загрузка сцен.

**Дополнительный референс:**
**luiz734/match3_game** — посмотреть структуру `grid.gd` и `match_3_core.gd`.

**Не брать в коммерческую основу:**
`gitbrent/godot-match-3`, потому что GPL-2.0.

---

# Целевая структура проекта

```text
match3-classic/
  project.godot
  export_presets.cfg

  addons/
	maaack_game_template/
	optional_match3_board/

  assets/
	tiles/
	boosters/
	ui/
	fx/
	sounds/
	music/
	fonts/
	licenses/

  scenes/
	boot/
	menus/
	game/
	  board/
	  tiles/
	  boosters/
	  levels/
	meta/
	  map/
	  shop/
	  rewards/

  scripts/
	core/
	  BoardController.gd
	  MatchDetector.gd
	  SwapController.gd
	  RefillController.gd
	  ComboController.gd
	level/
	  LevelConfig.gd
	  GoalSystem.gd
	  MoveSystem.gd
	economy/
	  CurrencySystem.gd
	  RewardSystem.gd
	save/
	  SaveService.gd

  data/
	levels/
	  level_001.tres
	  level_002.tres
	balance/
	  boosters.json
	  economy.json
	  difficulty_curve.json

  .github/
	workflows/
	  export-web.yml
	  export-android.yml
	  export-desktop.yml
```

---

# Что должен уметь наш первый MVP-билд

Минимально:

```text
8x8 поле
swap соседних элементов
поиск match 3 / 4 / 5
падение элементов вниз
refill сверху
очки
лимит ходов
цель уровня
win / lose state
10 уровней
простое меню
пауза
сохранение прогресса
Web export
Android export
```

Следующий слой:

```text
бомба за 4 фишки
ракета / линия
цветная супер-фишка за 5
комбо-цепочки
tutorial hand pointer
daily reward
карта уровней
бустеры до старта
бустеры внутри уровня
энергия / жизни
```

# Финальное решение

**Идеальный бесплатный билд для старта:**

```text
Kenney Starter Kit Match-3
+ Maaack Godot Game Template
+ Godot 4.6
+ свой UI/арт/мета-прогрессия
```

Это даст быструю рабочую основу, чистую лицензионную базу и нормальный путь к коммерческому прототипу.

[1]: https://github.com/KenneyNL/Starter-Kit-Match-3 "GitHub - KenneyNL/Starter-Kit-Match-3 · GitHub"
[2]: https://github.com/Maaack/Godot-Game-Template "GitHub - Maaack/Godot-Game-Template: Godot template with a main menu, options menus, pause menu, credits, scene loader, extra tools, and an example game scene. · GitHub"
[3]: https://godotengine.org/asset-library/asset/3405 "Match3 Board - Godot Asset Library"
[4]: https://github.com/luiz734/match3_game "GitHub - luiz734/match3_game: A simple, yet fully functional match 3 game created using Godot 4. · GitHub"
[5]: https://github.com/makifdb/godot-match3-template "GitHub - makifdb/godot-match3-template: https://godotengine.org/asset-library/asset/1099 · GitHub"
[6]: https://github.com/gitbrent/godot-match-3 "GitHub - gitbrent/godot-match-3: Godot Match 3 Game (GDScript 4.2) · GitHub"
