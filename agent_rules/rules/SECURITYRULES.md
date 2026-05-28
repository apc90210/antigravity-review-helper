# AGENT_SECURITY_RULES.md

## Назначение файла

Этот файл задаёт обязательные правила безопасности для любого агента, который работает в проекте Bookmaker / Betsline / ModHub.

Файл должен лежать в корне проекта:

```text
C:\bookmaker-modhub\AGENT_SECURITY_RULES.md
```

Любой агент обязан прочитать и соблюдать эти правила до выполнения задач.

---

# 1. Абсолютный workspace guard

Перед любыми действиями агент обязан проверить, что он находится в правильном репозитории.

```powershell
cd C:\bookmaker-modhub
$root = git rev-parse --show-toplevel
Write-Output "ROOT=$root"

if ($root -ne "C:/bookmaker-modhub" -and $root -ne "C:\bookmaker-modhub") {
    Write-Output "FINAL_STATUS: BLOCKED_WRONG_WORKSPACE"
    Write-Output "EXPECTED_REPO_PATH: C:\bookmaker-modhub"
    Write-Output "ACTUAL_REPO_PATH: $root"
    exit 1
}
```

Если проверка не прошла — остановиться. Не создавать файлы. Не продолжать задачу.

Запрещённые рабочие каталоги:

```text
C:\Users\Apc\.gemini\antigravity\scratch
C:\Users\Apc\.gemini\antigravity\brain
C:\anti-control
C:\bookmaker
/opt/betsline
```

Исключение: читать внешние Antigravity task/walkthrough-файлы можно только как справочный материал. Писать туда результаты проекта нельзя.

---

# 2. Release freeze / production guard

Если явно не сказано обратное owner-командой, действует release freeze.

Запрещено:

```text
production deploy
SSH на production
изменение Nginx
изменение firewall
изменение production env
docker compose на production
collectstatic/migrate на production
production DB write
```

Любые действия на production допустимы только при явном owner-token в задаче.

Пример owner-token:

```text
OWNER_APPROVED_PRODUCTION_ACTION=true
```

Без такого токена production считается запрещённым.

---

# 3. Git safety rules

Перед началом работы:

```powershell
git fetch origin
git branch --show-current
git status --short --untracked-files=all
git rev-parse HEAD
git rev-parse origin/develop
git rev-list --left-right --count origin/develop...HEAD
git submodule status
git -C betsline status --short --untracked-files=all
```

Запрещено:

```text
git add .
git push --force
git push --force-with-lease
git reset --hard без явного этапа preflight/recovery
git clean -fd без явного owner approval
git stash без причины и отчёта
самостоятельно merge в develop до owner-review, если задача этого не требует
```

Разрешено:

```text
git add <exact file paths only>
git commit с понятным сообщением
git push feature branch normal push
```

Если агент случайно сделал merge/push в develop до owner-review, он обязан остановиться и создать post-merge audit, а не продолжать следующий этап.

---

# 4. Branch discipline

Каждая задача работает только в указанной ветке.

Обычный порядок:

```text
1. preflight
2. checkout/update develop
3. create feature branch
4. implement
5. tests
6. static scans
7. docs/report/log
8. exact git add
9. commit
10. push feature branch
11. final structured response
```

Merge в develop разрешён только если задача явно говорит:

```text
controlled merge into develop
```

Если задача говорит `READY_FOR_OWNER_REVIEW`, merge в develop запрещён.

---

# 5. DB safety rules

По умолчанию все DB-действия должны быть read-only.

Запрещено без отдельного owner approval:

```sql
INSERT
UPDATE
DELETE
DROP
TRUNCATE
ALTER
CREATE
MERGE
COPY
```

Особо защищённые зоны:

```text
serving.predictions
ops.export_queue
approved.model_predictions
approved.model_artifacts
public/Sandbox-facing tables
production database
```

Для read-only проверок использовать только:

```sql
SELECT
BEGIN READ ONLY
SET TRANSACTION READ ONLY
```

Если нужна проверка схемы:

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('approved', 'modhub', 'core', 'betting')
ORDER BY table_schema, table_name;
```

Нельзя печатать DSN с паролем.

Плохо:

```text
postgresql://user:password@localhost:5434/db
```

Хорошо:

```text
postgresql://<redacted_user>:<redacted_password>@localhost:5434/<local_db>
```

---

# 6. Secrets hygiene

Запрещено выводить в чат, логи, docs, branch reports или terminal transcript:

```text
password
token
secret
API key
full DATABASE_URL
full DSN
.env dump
cookie
session
private key
OAuth secret
production IP + credentials связкой
```

Если секрет случайно выведен:

1. Зафиксировать `SECRET_HYGIENE_CAVEAT`.
2. Не повторять секрет.
3. Заменить в новых документах на `<redacted>`.
4. При необходимости рекомендовать rotation, если секрет production-like.

---

# 7. Public / Sandbox / Site exposure guard

До отдельного owner approval запрещено:

```text
публичные прогнозы
paid/public recommendations
Sandbox-visible recommendations
public routes для research models
public templates с ROI/edge/model probability
автоматическое продвижение модели
serving/export queue
```

Research metrics могут быть только:

```text
research-only
internal-only
not investment advice
not public profitability claim
not model promotion evidence
```

Обязательные формулировки для backtest/ROI:

```text
ROI is research-only.
ROI is not investment evidence.
ROI is not a public profitability claim.
Model promotion is blocked until owner acceptance.
Public claims are blocked.
Sandbox exposure is blocked.
```

---

# 8. Fallback / mock data rules

Mock/fallback/fixture данные не являются evidence.

Запрещено:

```text
выдавать mock/fallback metrics как real historical backtest
использовать fallback для REAL_DB_READY
скрыто включать fallback по PYTEST_CURRENT_TEST
делать tests green за счёт silent fallback
```

Разрешено только:

```text
explicit force_mock=True в тестах
явный MODHUB_FORCE_MOCK_FALLBACK только для non-evidence тестов
статус FALLBACK_REQUIRED_BUT_NOT_EVIDENCE
статус EXPLICIT_ONLY_NOT_EVIDENCE
```

Если fallback использован:

```text
REAL_DB_READY = false
REAL_BACKTEST_EXECUTION_MAY_CONTINUE = false
MODEL_PROMOTION_STATUS = BLOCKED
PUBLIC_CLAIMS_STATUS = BLOCKED
```

---

# 9. Real DB readiness rules

`REAL_DB_READY` можно ставить только если все условия true:

```text
driver import succeeds
connection succeeds
read-only guard passes
schema inventory succeeds
required tables exist
required columns exist
target data exists
fallback not used
DB writes absent
```

Если хотя бы одно условие false:

```text
REAL_DB_READY = false
REAL_BACKTEST_EXECUTION_MAY_CONTINUE = false
```

Status precedence:

```text
DRIVER_MISSING
DRIVER_INCOMPATIBLE
CONNECTION_BLOCKED
SCHEMA_MISSING
TABLE_MISSING
COLUMN_MISSING
DATA_INSUFFICIENT
ODDS_TIMESTAMPS_UNSAFE
READONLY_GUARD_FAILED
FALLBACK_REQUIRED_BUT_NOT_EVIDENCE
REAL_DB_READY
```

Нельзя писать:

```text
DRIVER_MISSING + CONNECTION_BLOCKED + REAL_DB_READY
```

Это противоречие и должно блокировать этап.

---

# 10. Odds timestamp / leakage rules

Строгое правило pre-match:

```text
odds_timestamp < kickoff
```

Если используются odds captured exactly at kickoff:

```text
odds_timestamp == kickoff
```

то они должны быть явно классифицированы как:

```text
closing_only_baseline
```

И не должны называться early/pre-match odds.

Если политика этапа требует строго `< kickoff`, то `== kickoff` должно быть заблокировано.

Любое изменение:

```text
>= kickoff -> > kickoff
```

обязано быть отражено в leakage policy, tests, docs и branch report.

---

# 11. xG / advanced stats safety

xG, shots, shots on target являются first-class internal data, но публично не раскрываются автоматически.

Для xG-моделей обязательно:

```text
owner-approved xG source package
coverage audit
storage contract
leakage audit
source_data_max_event_time_utc
as_of timestamp
no target match leakage
```

Без этого:

```text
xG plans = XG_BLOCKED
hybrid plans depending on xG = XG_BLOCKED
```

---

# 12. Tests policy

Агент обязан запускать тесты, указанные в задаче.

Если часть тестов не запускается, это не “all tests passed”.

Правильная формулировка:

```text
TESTS: 138 passed for requested research suite
TEST_SCOPE_CAVEAT: tests/modelhub not included due to local Python 3.14 C-extension compatibility
```

Неправильная формулировка:

```text
full test suite passed
```

если `tests/modelhub` был исключён.

---

# 13. Static safety scans

Перед финалом агент обязан выполнить static scans по изменённым пакетам и tests.

Минимальный набор forbidden patterns:

```text
serving.predictions
ops.export_queue
approved.model_predictions
approved.model_artifacts
public_approved
sandbox_approved
auto_approve
production_ready
promoted
model_approved
ssh
paramiko
DROP TABLE
TRUNCATE
DELETE FROM
UPDATE 
INSERT INTO
ALTER TABLE
CREATE TABLE
.fit(
.predict(
.predict_proba(
sklearn
pandas
numpy
DataFrame
ndarray
model_artifacts
sandbox_public_recommendations
investment evidence
profitability claim
git push --force
--force
password
secret
token
```

False positives разрешены только если явно объяснены.

---

# 14. Documentation requirements

Каждый этап обязан создавать или обновлять:

```text
docs/plans/<stage_name>.md
docs/v1_audit/branch_reports/<stage_name>.md
logs/YYYY-MM-DD.md
```

Antigravity artifacts не заменяют проектные docs:

```text
task.md
walkthrough.md
implementation_plan.md
```

Если они созданы в `.gemini\antigravity\brain`, это не считается project deliverable.

---

# 15. Required final response format

Финальный ответ агента всегда должен включать:

```text
FINAL_STATUS: <exact status>
REPO_PATH: C:\bookmaker-modhub
BRANCH: <branch>
HEAD: <commit>
ORIGIN_DEVELOP_HEAD: <commit>
AHEAD_BEHIND: ahead <n>, behind <n>
CHANGED_FILES:
  - <files>
TESTS: <summary>
TEST_SCOPE_CAVEAT: <or NONE>
STATIC_SCANS: <PASS/BLOCKED>
DB_SAFETY: <PASS/BLOCKED>
PUBLIC_SANDBOX_EXPOSURE: <PASS/BLOCKED>
PRODUCTION_ACTIONS: <PASS/BLOCKED>
FORCE_PUSH_STATUS: NO_FORCE_PUSH_USED
PUSH_STATUS: <PUSHED/NOT_PUSHED>
NEXT_RECOMMENDED_BRANCH: <branch>
```

Для DB/backtest этапов дополнительно:

```text
REAL_DB_READINESS_CHECK: <PASS/BLOCKED>
FALLBACK_STATUS: <NOT_USED / REQUIRED_BUT_NOT_EVIDENCE>
EXECUTION_MATRIX:
  - plan_epl_market_baseline_v1: <status>
  - plan_esp_elo_baseline_v1: <status>
  - plan_ita_odds_timing_v1: <status>
  - plan_ger_xg_advanced_v1: <status>
  - plan_fra_hybrid_v0_v1: <status>
  - plan_rus_baseline_v1: <status>
ROI_INTERPRETATION: research-only; not investment evidence; not public profitability claim
MODEL_PROMOTION_STATUS: BLOCKED
PUBLIC_CLAIMS_STATUS: BLOCKED
```

---

# 16. Stop conditions

Агент обязан остановиться и вернуть `BLOCKED`, если:

```text
wrong workspace
dirty unexpected worktree
dirty submodule
missing branch
tests fail
DB write detected
production action detected
public/Sandbox exposure detected
secret printed
force push required
fallback masks readiness
REAL_DB_READY contradiction
leakage policy contradiction
required docs missing
```

---

# 17. Project-specific current rule

На текущем этапе проекта:

```text
MVP V1 deployed + post-deploy accepted
release freeze active
ModHub advanced models are research-only
public claims blocked
model promotion blocked
Sandbox exposure blocked
production actions blocked
```

Следующие model/backtest этапы должны оставаться:

```text
local-only
read-only
research-only
owner-review gated
no serving/export
no production deploy
```

---

# 18. Agent checklist before final response

Перед финальным ответом агент обязан проверить:

```text
[ ] repo path is C:\bookmaker-modhub
[ ] branch is correct
[ ] worktree clean or only intended files staged/committed
[ ] submodule clean
[ ] no git add .
[ ] no force push
[ ] no production action
[ ] no DB writes
[ ] no secrets in output/docs/logs
[ ] required tests run
[ ] test scope caveat stated
[ ] static scans run
[ ] docs/plans created
[ ] docs/v1_audit/branch_reports created
[ ] logs/YYYY-MM-DD.md updated
[ ] exact changed files listed
[ ] final HEAD recorded
[ ] origin/develop HEAD recorded
[ ] ahead/behind recorded
[ ] push status recorded
[ ] next branch recommended
```

If any box cannot be checked, final status must be `BLOCKED` or `ACCEPTED_WITH_CAVEAT`, not clean accepted.
