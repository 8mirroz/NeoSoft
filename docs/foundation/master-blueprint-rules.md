# Neo Soft Frost — Операционные правила разработки

> Извлечено из мастер-чертежа (82 источника NotebookLM Deushare + p1/p2/libra)  
> Дата: 2026-05-26

---

## RULE-001: Source-of-Truth Hierarchy

```yaml
priority_order:
  1: docs/foundation/*.md
  2: data/levels/*.json
  3: data/balance/*.json
  4: p1.md                         # Визуальный стандарт
  5: p2.md                         # Продуктовый скоп
  6: libra.md                      # Лицензии, ассеты
  7: NotebookLM Deushare           # Стратегический гайд
```

---

## RULE-002: Research-First для сложных решений

```
IF decision TOUCHES (balance OR retention OR monetization OR difficulty):
  1. Запросить NotebookLM Deushare
  2. Процитировать источник
  3. Записать в decision-log.md
ELSE IF нет внешнего источника:
  MARK AS "Local assumption"
```

Инструмент: `./scripts/notebooklm_safe.sh ask "<вопрос>" --timeout 120`

---

## RULE-003: Визуальные гейты

```
BEFORE Phase C freeze:
  - Gem readability at 64×64 and 96×96 → ≥90% correct classification
  - Contrast: gems visible against board on target devices
  - Animation timings within p1.md spec ranges
  - No hard black outlines; separation via glow/AO/subtle edges
```

### Тайминги (из p1.md + NotebookLM)

| Анимация | Мин | Макс |
|---|---|---|
| Idle-цикл | 3.0s | 6.0s |
| Select | 0.18s | 0.35s |
| Swap | 0.22s | 0.35s |
| Match dissolve | 0.35s | 0.60s |
| Spawn | 0.25s | 0.45s |
| UI PopUp | 0.20s | 0.50s |

---

## RULE-004: Лицензионная чистота

```yaml
allowed:         [MIT, Apache-2.0, CC0]
attribution_req: [CC-BY]        # → assets/licenses/credits.md
forbidden:       [GPL]          # в production code path
```

Каждый ассет: source URL, license, author, date added.

---

## RULE-005: Архитектурные запреты

1. `core_match3` и `level_runtime` НЕ зависят от HUD/menu сцен
2. `presentation_layer` НЕ мутирует board state
3. Коммуникация ТОЛЬКО через сигналы/события
4. Баланс и цели ТОЛЬКО из data-файлов

Сигналы: `swap_requested → swap_resolved → match_resolved → cascade_completed → goals_updated → level_finished`

---

## RULE-006: VFX Quality Gates

1. Радиус эффекта ≤ 1 клетки от центра
2. Каскадная задержка: 1-2 кадра (~0.05 сек) между элементами
3. Цвет эффекта = цвету фишки ТОЛЬКО для цветозависимых; обычные — нейтральные
4. Тест на «эффект бутерброда»: одновременные VFX не создают кашу
5. Тест на пересвет: эффекты видны на нашем светлом фоне (подложка!)
6. Физика: упругость, вес, инерция передаются анимацией

---

## RULE-007: Этичная монетизация

### Запрещено

- Скрытые вероятности
- Фейковые зачёркнутые цены (якорь)
- Свинка-копилка
- Эскалация стоимости «+5 ходов»
- Давление через фрустрацию

### Разрешено

- Rewarded ads (добровольно)
- Cosmetic packs (красота, не power)
- Мягкий FOMO (сезонные темы без жёстких дедлайнов)
- Starter Pack (без paywall)
