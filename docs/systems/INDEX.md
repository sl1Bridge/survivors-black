# Реестр систем

ЕДИНСТВЕННЫЙ источник зависимостей между системами и ссылок на код, данные и тесты.
Страницы систем эти сведения НЕ дублируют: SYS-ID в заголовке страницы — только ссылка на запись этого реестра.

Таблица ведётся вручную и пока НЕ проверяется автоматически
(статус «TBD» в `../workflow/testing.md`). Держи формат машиночитаемым:
одна строка на систему, несколько путей — через запятую.
Все пути — относительно корня репозитория.

| SYS-ID | Страница | Код | Данные | Тесты | Зависит от |
|---|---|---|---|---|---|
| SYS-ARENA | `docs/systems/arena.md` | `project.godot`, `scenes/main.tscn` | — | `tests/test_gameplay.gd` | — |
| SYS-PLAYER | `docs/systems/player.md` | `scenes/player.tscn`, `scripts/player.gd` | — | `tests/test_gameplay.gd`, `tests/test_player_movement.gd` | SYS-ARENA |
| SYS-ENEMIES | `docs/systems/enemies.md` | `scenes/enemy.tscn`, `scripts/enemy.gd`, `scripts/enemy_spawner.gd` | — | `tests/test_gameplay.gd` | SYS-ARENA, SYS-PLAYER |
| SYS-INVENTORY | `docs/systems/inventory.md` | `scripts/inventory.gd` | — | `tests/test_gameplay.gd` | — |
| SYS-COMBAT | `docs/systems/combat.md` | `scenes/projectile.tscn`, `scripts/pistol.gd`, `scripts/projectile.gd` | — | `tests/test_gameplay.gd` | SYS-PLAYER, SYS-ENEMIES, SYS-INVENTORY |
| SYS-PICKUPS | `docs/systems/pickups.md` | `scenes/pickup.tscn`, `scripts/pickup.gd`, `scripts/pickup_manager.gd` | — | `tests/test_gameplay.gd` | SYS-ARENA, SYS-PLAYER, SYS-ENEMIES |
| SYS-PROGRESSION | `docs/systems/progression.md` | `scripts/progression.gd` | — | `tests/test_gameplay.gd` | SYS-INVENTORY, SYS-PICKUPS |
| SYS-HUD | `docs/systems/hud.md` | `scripts/hud.gd` | — | `tests/test_gameplay.gd` | SYS-PLAYER, SYS-INVENTORY, SYS-PICKUPS, SYS-PROGRESSION, SYS-RUN |
| SYS-SAVE | `docs/systems/save.md` | `scripts/game_profile.gd` | — | `tests/test_profile.gd`, `tests/test_run_flow.gd` | — |
| SYS-META-PROGRESSION | `docs/systems/meta-progression.md` | `scripts/game_profile.gd`, `scripts/upgrades_menu.gd` | — | `tests/test_profile.gd`, `tests/test_menus.gd`, `tests/test_run_flow.gd` | SYS-SAVE |
| SYS-AUDIO | `docs/systems/audio.md` | `scripts/game_profile.gd`, `scripts/settings_menu.gd` | — | `tests/test_profile.gd`, `tests/test_menus.gd` | SYS-SAVE |
| SYS-MENU | `docs/systems/menu.md` | `scenes/main_menu.tscn`, `scenes/settings_menu.tscn`, `scenes/upgrades_menu.tscn`, `scripts/main_menu.gd`, `scripts/settings_menu.gd`, `scripts/upgrades_menu.gd` | — | `tests/test_menus.gd`, `tests/test_run_flow.gd` | SYS-RUN, SYS-META-PROGRESSION, SYS-AUDIO, SYS-SAVE |
| SYS-RUN | `docs/systems/run.md` | `scenes/main.tscn`, `scripts/main.gd` | — | `tests/test_gameplay.gd`, `tests/test_menus.gd`, `tests/test_run_flow.gd` | SYS-ARENA, SYS-PLAYER, SYS-ENEMIES, SYS-COMBAT, SYS-INVENTORY, SYS-PICKUPS, SYS-PROGRESSION, SYS-HUD, SYS-MENU, SYS-SAVE, SYS-META-PROGRESSION |

Формат строки — пример ВНЕ реестра, это не запись:

| SYS-COMBAT | `docs/systems/combat.md` | `src/combat/…` | `content/combat/…` | `tests/test_combat.ext` | SYS-ITEMS, SYS-EFFECTS |

Правила:

- SYS-ID постоянен и не совпадает с отображаемым названием системы.
- Новая система = новая строка в таблице выше + страница по `_template.md`.
- Запись контента, целиком задаваемая данными, отдельной страницы не получает.
- Чтобы оценить последствия изменения, смотри колонку «Зависит от» в обе стороны:
  на что система опирается и кто опирается на неё.
- Реестр начинается пустым: первая строка появляется вместе с первой реальной системой.
